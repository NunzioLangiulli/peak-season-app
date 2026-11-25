"""Adds a released version to the SideStore/AltStore source (sidestore/source.json).

Run by the "iOS build" workflow when a release is published, after the .ipa
has been attached to the release. The new version goes first in the list;
an entry with the same version number is replaced.

Usage:
  python sidestore/update_source.py --version 1.3.1 --tag v1.3.1 \
      --ipa PeakSeason-1.3.1-unsigned.ipa --size 108277154 \
      --date 2026-11-26T10:00:00Z
"""

import argparse
import json
from pathlib import Path

REPO_URL = "https://github.com/NunzioLangiulli/peak-season-app"
SOURCE = Path(__file__).resolve().parent / "source.json"
MIN_IOS = "15.0"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--ipa", required=True)
    parser.add_argument("--size", required=True, type=int)
    parser.add_argument("--date", required=True)
    args = parser.parse_args()

    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    app = source["apps"][0]

    entry = {
        "version": args.version,
        "date": args.date,
        "localizedDescription": f"What's new in Peak Season {args.version}: {REPO_URL}/releases/tag/{args.tag}",
        "downloadURL": f"{REPO_URL}/releases/download/{args.tag}/{args.ipa}",
        "size": args.size,
        "minOSVersion": MIN_IOS,
    }
    versions = [v for v in app.get("versions", []) if v.get("version") != args.version]
    app["versions"] = [entry] + versions

    SOURCE.write_text(json.dumps(source, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"SideStore source updated to {args.version}")


if __name__ == "__main__":
    main()
