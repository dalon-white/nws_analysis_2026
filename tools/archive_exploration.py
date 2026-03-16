#!/usr/bin/env python
"""Archive exploration notebooks into notebooks/archive/<timestamp>/ and
append an entry to DECISIONS.md listing archived files.

Usage:
    python tools/archive_exploration.py
"""

from datetime import datetime
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
EXPLORATION_DIR = ROOT / "notebooks" / "exploration"
ARCHIVE_DIR = ROOT / "notebooks" / "archive"
DECISIONS_FILE = ROOT / "DECISIONS.md"
EXCLUDE = {".gitkeep", "README.md"}


def list_files_to_archive():
    return [p for p in EXPLORATION_DIR.iterdir() if p.is_file() and p.name not in EXCLUDE]


def ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)


def append_decisions_entry(archived_files, archive_path):
    lines = []
    lines.append(f"\n---\n\n### {datetime.now().date()} – Exploration archived to `{archive_path}`")
    lines.append("**Files archived:**")
    for file_path in archived_files:
        lines.append(f"- `{file_path.name}`")
    lines.append("**Notes:**")
    lines.append("- Archived exploration notebooks to preserve the investigative trail.")
    lines.append("- Refer to these snapshots for methods considered but not used.")
    content = "\n".join(lines) + "\n"
    with open(DECISIONS_FILE, "a", encoding="utf-8") as file_handle:
        file_handle.write(content)


def main():
    files = list_files_to_archive()
    if not files:
        print("No exploration files to archive.")
        return

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    target = ARCHIVE_DIR / stamp
    ensure_dir(target)

    for file_path in files:
        shutil.move(str(file_path), target / file_path.name)
        print(f"Moved: {file_path.name} -> {target}")

    append_decisions_entry(files, target)
    print("Updated DECISIONS.md with archive entry.")
    print("Done.")


if __name__ == "__main__":
    main()
