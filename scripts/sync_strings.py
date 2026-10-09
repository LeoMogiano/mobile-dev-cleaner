#!/usr/bin/env python3
"""Syncs Localizable.xcstrings with the keys the compiler extracted (*.stringsdata).

xcodebuild emits the keys but only the Xcode IDE writes them into the catalog; this script
does that step from the command line. Existing translations are kept, stale keys are dropped.

Usage: scripts/sync_strings.py [derived-data-path] [--missing]
"""
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "MobileDevCleaner", "Resources", "Localizable.xcstrings")


def extracted_keys(derived_data):
    pattern = os.path.join(derived_data, "Build", "Intermediates.noindex", "MobileDevCleaner.build",
                           "*", "MobileDevCleaner.build", "Objects-normal", "*", "*.stringsdata")
    keys = set()
    for path in glob.glob(pattern):
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
        for entry in data.get("tables", {}).get("Localizable", []):
            keys.add(entry["key"])
    return keys


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    derived_data = args[0] if args else os.path.join(ROOT, "build", "dd")
    keys = extracted_keys(derived_data)
    if not keys:
        sys.exit("No .stringsdata found: build first.")

    with open(CATALOG, encoding="utf-8") as handle:
        catalog = json.load(handle)
    old = catalog.get("strings", {})
    catalog["strings"] = {key: old.get(key, {}) for key in sorted(keys)}

    with open(CATALOG, "w", encoding="utf-8") as handle:
        json.dump(catalog, handle, ensure_ascii=False, indent=2, separators=(",", " : "))
        handle.write("\n")

    missing = [k for k, v in catalog["strings"].items()
               if not v.get("localizations", {}).get("en", {}).get("stringUnit", {}).get("value")]
    print(f"{len(keys)} keys, {len(missing)} without English, {len(set(old) - keys)} stale removed")
    if "--missing" in sys.argv:
        for key in missing:
            print(json.dumps(key, ensure_ascii=False))


if __name__ == "__main__":
    main()
