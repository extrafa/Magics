#!/usr/bin/env python3
"""Fail if a scheme other than "Magics (TestFlight)" archives a build with tester-only code,
or if any scheme would archive the app under a bundle id other than the App Store one.

BETA and DEBUG compile in the "TestFlight" settings section (Pro override, hidden watermark).
Only the TestFlight scheme may archive such a configuration.

The bundle id is checked because the gitignored Config/Local.xcconfig overrides it (and the signing)
for local builds: an archive made while that file exists cannot be uploaded to the App Store record.

Usage: check-archive-configs.py [path/to/Project.xcodeproj]
"""
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

TESTER_SCHEME = "Magics (TestFlight)"
TESTER_FLAGS = {"BETA", "DEBUG"}
APP_TARGET = "MagicTricks"
APP_BUNDLE_ID = "net.svoego.magic"


def archive_configuration(scheme_path):
    archive = ET.parse(scheme_path).getroot().find("ArchiveAction")
    return archive.get("buildConfiguration") if archive is not None else None


def build_settings(project, scheme, configuration):
    """Returns (tester flags set, resolved bundle id of the app target)."""
    result = subprocess.run(
        ["xcodebuild", "-project", str(project), "-scheme", scheme,
         "-configuration", configuration, "-showBuildSettings"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"xcodebuild failed for {scheme} / {configuration}:\n{result.stderr}")
    flags = set()
    bundle_id = None
    target = None
    for line in result.stdout.splitlines():
        stripped = line.strip()
        if stripped.startswith("Build settings for action"):
            target = stripped.rstrip(":").rpartition(" target ")[2]
            continue
        key, _, value = stripped.partition(" = ")
        # Release leaves the setting unset, which means no flags.
        if key == "SWIFT_ACTIVE_COMPILATION_CONDITIONS":
            flags |= set(value.split())
        elif key == "PRODUCT_BUNDLE_IDENTIFIER" and target == APP_TARGET:
            bundle_id = value
    return flags, bundle_id


def main():
    project = Path(sys.argv[1] if len(sys.argv) > 1 else "MagicTricks.xcodeproj")
    schemes = sorted((project / "xcshareddata" / "xcschemes").glob("*.xcscheme"))
    if not schemes:
        print(f"No shared schemes found in {project}")
        return 1

    failures = []
    for path in schemes:
        scheme = path.stem
        configuration = archive_configuration(path)
        if configuration is None:
            failures.append(f"{scheme}: no ArchiveAction, cannot tell what it archives")
            continue
        flags, bundle_id = build_settings(project, scheme, configuration)
        print(f"{scheme}: archives {configuration}, flags {sorted(flags) or 'none'}, bundle id {bundle_id}")
        if bundle_id != APP_BUNDLE_ID:
            failures.append(
                f"{scheme}: archives {configuration} as \"{bundle_id}\", not \"{APP_BUNDLE_ID}\"; "
                f"move Config/Local.xcconfig away before archiving"
            )
        if scheme != TESTER_SCHEME and flags & TESTER_FLAGS:
            failures.append(
                f"{scheme}: archives {configuration} with {sorted(flags & TESTER_FLAGS)}; "
                f"only \"{TESTER_SCHEME}\" may archive tester-only code"
            )

    for message in failures:
        print(f"ERROR: {message}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
