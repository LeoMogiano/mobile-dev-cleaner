#!/usr/bin/env python3
"""Syncs Localizable.xcstrings with the keys the compiler extracted (*.stringsdata).

xcodebuild emits the keys but only the Xcode IDE writes them into the catalog; this script
does that step from the command line. Existing translations are kept, stale keys are dropped.
It then reports, per language, the keys without a translation and the translations whose
format specifiers (%lld, %@, ...) differ from the key.

Usage: scripts/sync_strings.py [derived-data-path] [--missing]
"""
import glob
import json
import os
import re
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "MobileDevCleaner", "Resources", "Localizable.xcstrings")
LANGS = ["en", "ja", "zh-Hans", "pt-BR", "de"]
SPECIFIER = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|@|%)")


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


def translation_values(entry, lang):
    """Strings for one language: the stringUnit, or every plural form when 'other' is set."""
    localization = entry.get("localizations", {}).get(lang, {})
    value = localization.get("stringUnit", {}).get("value")
    if value:
        return [value]
    plural = localization.get("variations", {}).get("plural", {})
    if plural.get("other", {}).get("stringUnit", {}).get("value"):
        return [form["stringUnit"]["value"] for form in plural.values() if form.get("stringUnit", {}).get("value")]
    return []


def specifiers(text):
    # Positional "%1$@" and "%@" count as the same specifier.
    return Counter(re.sub(r"\d+\$", "", match) for match in SPECIFIER.findall(text))


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

    missing = {lang: [] for lang in LANGS}
    mismatches = []
    for key, entry in catalog["strings"].items():
        expected = specifiers(key)
        for lang in LANGS:
            values = translation_values(entry, lang)
            if not values:
                missing[lang].append(key)
            for value in values:
                if specifiers(value) != expected:
                    mismatches.append((lang, key, value))

    print(f"{len(keys)} keys, {len(set(old) - keys)} stale removed")
    for lang in LANGS:
        print(f"{lang}: {len(missing[lang])} missing")
    for lang, key, value in mismatches:
        print(f"{lang}: {key} -> {value}")
    if "--missing" in sys.argv:
        for lang in LANGS:
            print(f"\nMissing in {lang}:")
            for key in missing[lang]:
                print(json.dumps(key, ensure_ascii=False))


if __name__ == "__main__":
    main()
