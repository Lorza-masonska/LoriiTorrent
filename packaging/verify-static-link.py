#!/usr/bin/env python3
"""Reject a qBittorrent Ninja build that selected a different libtorrent."""

import argparse
import json
from pathlib import Path
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build-dir", type=Path, required=True, dest="buildDir")
    parser.add_argument("--manifest", type=Path, required=True)
    arguments = parser.parse_args()
    manifest = json.loads(arguments.manifest.read_text(encoding="utf-8"))
    if manifest["linkage"] != "static":
        parser.error("The libtorrent manifest does not describe static linkage")
    cache = (arguments.buildDir / "CMakeCache.txt").read_text(encoding="utf-8")
    packageDir = next((line.split("=", 1)[1] for line in cache.splitlines()
                        if line.startswith("LibtorrentRasterbar_DIR:")), None)
    if packageDir is None or Path(packageDir).resolve() != Path(manifest["cmake_package_dir"]).resolve():
        parser.error("qBittorrent selected a different libtorrent CMake package")
    ninja = (arguments.buildDir / "build.ninja").read_text(encoding="utf-8")
    ninja = ninja.replace("$:", ":").replace("$ ", " ").replace("$\n", "").replace("\\", "/")
    archive = Path(manifest["static_archive"]).as_posix()
    if archive.casefold() not in ninja.casefold():
        parser.error("The expected static libtorrent archive is missing from qBittorrent's link recipe")
    print("Verified explicit static libtorrent: " + archive)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        print("Static linkage verification failed: " + str(error), file=sys.stderr)
        sys.exit(1)
