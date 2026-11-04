#!/usr/bin/env python3
"""Safely restore the original METRO: THE CITY V10 source ZIP.

The transfer may store a numbered fragment as one file or as ordered sub-fragments.
No extraction occurs unless the joined archive is complete and passes ZIP validation.
"""
from __future__ import annotations

import base64
import binascii
import hashlib
import io
import re
import sys
import zipfile
from pathlib import Path, PurePosixPath
from typing import NoReturn

ROOT = Path(__file__).resolve().parents[1]
TRANSFER_DIR = ROOT / ".source_transfer"
PART_COUNT = 10
MAX_UNCOMPRESSED_BYTES = 256 * 1024 * 1024


def fail(message: str) -> NoReturn:
    print(f"[restore] ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def read_fragment(number: int) -> str:
    stem = f"part-{number:02d}"
    whole_path = TRANSFER_DIR / f"{stem}.txt"
    if whole_path.is_file():
        return whole_path.read_text(encoding="ascii").strip()

    segment_pattern = re.compile(rf"^{re.escape(stem)}-(\d+)\.txt$")
    segments: list[tuple[int, Path]] = []
    for path in TRANSFER_DIR.glob(f"{stem}-*.txt"):
        match = segment_pattern.match(path.name)
        if match:
            segments.append((int(match.group(1)), path))
    if not segments:
        fail(f"missing fragment {stem}.txt (or its numbered sub-fragments)")

    segments.sort(key=lambda item: item[0])
    numbers = [item[0] for item in segments]
    expected = list(range(1, numbers[-1] + 1))
    if numbers != expected:
        missing = sorted(set(expected) - set(numbers))
        fail(f"{stem} has missing sub-fragment numbers: {missing}")

    content = []
    for _, path in segments:
        try:
            content.append(path.read_text(encoding="ascii").strip())
        except (UnicodeError, OSError) as exc:
            fail(f"cannot read {path.name}: {exc}")
    return "".join(content)


def main() -> None:
    fragments: list[str] = []
    seen_hashes: dict[str, str] = {}

    for number in range(1, PART_COUNT + 1):
        try:
            fragment = read_fragment(number)
        except (UnicodeError, OSError) as exc:
            fail(f"cannot read fragment {number:02d}: {exc}")
        if not fragment:
            fail(f"fragment {number:02d} is empty")
        digest = hashlib.sha256(fragment.encode("ascii")).hexdigest()
        if digest in seen_hashes:
            fail(
                f"fragment {number:02d} duplicates {seen_hashes[digest]}; "
                "the transfer would produce a corrupted ZIP"
            )
        seen_hashes[digest] = f"part-{number:02d}"
        fragments.append(fragment)

    try:
        archive_bytes = base64.b64decode("".join(fragments), validate=True)
    except (binascii.Error, ValueError) as exc:
        fail(f"the joined fragments are not valid Base64: {exc}")

    if not zipfile.is_zipfile(io.BytesIO(archive_bytes)):
        fail("the joined data is not a complete ZIP archive")

    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        bad_member = archive.testzip()
        if bad_member:
            fail(f"ZIP CRC check failed for {bad_member!r}")

        names = archive.namelist()
        if "project.godot" not in names:
            fail("project.godot is missing from the archive")
        total_size = sum(info.file_size for info in archive.infolist())
        if total_size > MAX_UNCOMPRESSED_BYTES:
            fail(
                f"archive expands to {total_size:,} bytes, above the "
                f"{MAX_UNCOMPRESSED_BYTES:,}-byte safety limit"
            )

        root_resolved = ROOT.resolve()
        for info in archive.infolist():
            member = PurePosixPath(info.filename)
            if member.is_absolute() or ".." in member.parts:
                fail(f"unsafe ZIP path: {info.filename!r}")
            target = (ROOT / Path(*member.parts)).resolve()
            try:
                target.relative_to(root_resolved)
            except ValueError:
                fail(f"ZIP path escapes the project folder: {info.filename!r}")

        archive.extractall(ROOT)

    print(
        f"[restore] Success: restored {len(names)} entries "
        f"({total_size:,} uncompressed bytes) into {ROOT}"
    )


if __name__ == "__main__":
    main()
