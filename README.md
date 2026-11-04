# METRO: THE CITY

Godot 4 Android game project. The intended engine version is Godot 4.3 or newer, with the Compatibility renderer (OpenGL ES 3).

## Restoring the V10 source

The original V10 project archive is transferred as ten ordered Base64 fragments in `.source_transfer/part-01.txt` through `.source_transfer/part-10.txt`.

The restoration tool is:

```bash
python tools/restore_source_archive.py
```

It validates that all ten fragments exist, checks the Base64 data and ZIP CRCs, verifies that `project.godot` is present, and rejects unsafe archive paths before extracting anything into the repository.

A GitHub Actions workflow named **Restore V10 source archive** runs when a transfer fragment is pushed. It can also be started manually from the repository's **Actions** tab. After a successful restore, the workflow commits the Godot source files to the default branch.

The game source is not considered restored until the workflow completes successfully and `project.godot` appears in the repository root.
