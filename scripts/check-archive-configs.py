#!/usr/bin/env python3
"""Fail if a scheme other than "Magics (TestFlight)" archives a build with tester-only code.

BETA and DEBUG compile in the "TestFlight" settings section (Pro override, hidden watermark).
Only the TestFlight scheme may archive such a configuration.

Usage: check-archive-configs.py [path/to/Project.xcodeproj]
"""
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

TESTER_SCHEME = "Magics (TestFlight)"
TESTER_FLAGS = {"BETA", "DEBUG"}


def archive_configuration(scheme_path):
    archive = ET.parse(scheme_path).getroot().find("ArchiveAction")
    return archive.get("buildConfiguration") if archive is not None else None


def compilation_flags(project, scheme, configuration):
    result = subprocess.run(
        ["xcodebuild", "-project", str(project), "-scheme", scheme,
         "-configuration", configuration, "-showBuildSettings"],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(f"xcodebuild failed for {scheme} / {configuration}:\n{result.stderr}")
    flags = set()
    for line in result.stdout.splitlines():
        key, _, value = line.strip().partition(" = ")
        # Release leaves the setting unset, which means no flags.
        if key == "SWIFT_ACTIVE_COMPILATION_CONDITIONS":
            flags |= set(value.split())
    return flags


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
        flags = compilation_flags(project, scheme, configuration)
        print(f"{scheme}: archives {configuration}, flags {sorted(flags) or 'none'}")
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
