#!/usr/bin/env python3
"""Safely restore the original METRO: THE CITY V10 source ZIP.

The archive is stored as nine ordered Base64 text fragments in .source_transfer.
This script deliberately refuses to extract an incomplete, duplicated, or invalid
archive so a damaged transfer can never overwrite the working project.
"""
from __future__ import annotations

import base64
import binascii
import hashlib
import io
import sys
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
TRANSFER_DIR = ROOT / ".source_transfer"
PART_COUNT = 9
MAX_UNCOMPRESSED_BYTES = 256 * 1024 * 1024


def fail(message: str) -> "NoReturn":
    print(f"[restore] ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    fragments: list[str] = []
    missing: list[str] = []
    hashes: dict[str, str] = {}

    for number in range(1, PART_COUNT + 1):
        path = TRANSFER_DIR / f"part-{number:02d}.txt"
        if not path.is_file():
            missing.append(path.name)
            continue
        try:
            content = path.read_text(encoding="ascii").strip()
        except (UnicodeError, OSError) as exc:
            fail(f"cannot read {path.name}: {exc}")
        if not content:
            fail(f"{path.name} is empty")
        digest = hashlib.sha256(content.encode("ascii")).hexdigest()
        if digest in hashes:
            fail(
                f"{path.name} is an exact duplicate of {hashes[digest]}; "
                "the transfer would produce a corrupted ZIP"
            )
        hashes[digest] = path.name
        fragments.append(content)

    if missing:
        fail("missing fragment(s): " + ", ".join(missing))

    encoded = "".join(fragments)
    try:
        archive_bytes = base64.b64decode(encoded, validate=True)
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
