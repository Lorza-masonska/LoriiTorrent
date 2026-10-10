#!/usr/bin/env python3
"""Build an isolated, pinned static libtorrent with an explicit patch mode."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys


LIBTORRENT_COMMIT = "1eb18faeae156d8dbbab42935c082f8b81f50989"
LIBTORRENT_VERSION = "2.0.15"
LIBTORRENT_REPOSITORY = "https://github.com/arvidn/libtorrent.git"
PACKAGE_ROOT = Path(__file__).resolve().parent.parent


def run(arguments, *, capture=False, cwd=None):
    return subprocess.run(
        [str(argument) for argument in arguments],
        check=True,
        stdout=subprocess.PIPE if capture else None,
        text=True,
        cwd=cwd,
    ).stdout


def digestFile(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("ON", "OFF"), default="ON")
    parser.add_argument("--build-root", type=Path, default=PACKAGE_ROOT / "build", dest="buildRoot")
    parser.add_argument("--source", type=Path, default=os.environ.get("LIBTORRENT_SOURCE"))
    parser.add_argument("--patch-dir", type=Path, default=PACKAGE_ROOT / "packaging" / "patches", dest="patchDir")
    parser.add_argument("--jobs", type=int, default=2)
    parser.add_argument("--result", type=Path, required=True)
    parser.add_argument("--cmake-arg", action="append", default=[], dest="cmakeArg")
    parser.add_argument("cmakeArgs", nargs=argparse.REMAINDER)
    arguments = parser.parse_args()
    if arguments.jobs < 1:
        parser.error("--jobs must be positive")
    forwarded = arguments.cmakeArgs[1:] if arguments.cmakeArgs[:1] == ["--"] else arguments.cmakeArgs
    arguments.cmakeArg += forwarded

    patches = sorted(arguments.patchDir.resolve().glob("*.patch")) if arguments.mode == "ON" else []
    if arguments.mode == "ON" and not patches:
        parser.error("Patch mode ON requires reviewed patch files in " + str(arguments.patchDir))
    patchManifest = [{"name": path.name, "sha256": digestFile(path)} for path in patches]
    recipe = {
        "commit": LIBTORRENT_COMMIT,
        "version": LIBTORRENT_VERSION,
        "patch_mode": arguments.mode,
        "patches": patchManifest,
        "linkage": "static",
        "cmake_arguments": arguments.cmakeArg,
    }
    fingerprint = hashlib.sha256(json.dumps(recipe, sort_keys=True).encode()).hexdigest()[:12]
    modeName = "patched" if arguments.mode == "ON" else "baseline"
    platformName = "windows" if os.name == "nt" else "linux"
    variant = f"{platformName}-{modeName}-{fingerprint}"
    buildRoot = arguments.buildRoot.resolve()
    sourcePath = buildRoot / "deps" / f"libtorrent-{LIBTORRENT_VERSION}-{variant}"
    buildPath = buildRoot / f"libtorrent-{variant}"
    prefix = buildRoot / "deps" / f"libtorrent-install-{variant}"
    marker = sourcePath.parent / (sourcePath.name + ".prepared.json")
    sourcePath.parent.mkdir(parents=True, exist_ok=True)

    localSource = arguments.source
    bundledManifest = None
    if localSource is None:
        candidate = PACKAGE_ROOT / "build" / "deps" / "libtorrent"
        if (candidate / ".git").exists():
            localSource = candidate
        elif (PACKAGE_ROOT / "dependencies/libtorrent-source.json").is_file():
            localSource = PACKAGE_ROOT / "dependencies/libtorrent"
    if localSource is not None:
        localSource = localSource.resolve()
        manifestPath = localSource.parent / "libtorrent-source.json"
        if not (localSource / ".git").exists() and manifestPath.is_file():
            bundledManifest = json.loads(manifestPath.read_text(encoding="utf-8"))
            if bundledManifest.get("commit") != LIBTORRENT_COMMIT:
                parser.error("Bundled source manifest does not match the pinned libtorrent commit")
            actualFiles = {p.relative_to(localSource).as_posix() for p in localSource.rglob("*") if p.is_file()}
            if actualFiles != set(bundledManifest["files"]):
                parser.error("Bundled libtorrent source file set differs from its manifest")
            for relative, expected in bundledManifest["files"].items():
                path = localSource / relative
                if path.is_symlink() or not path.resolve().is_relative_to(localSource) or digestFile(path) != expected:
                    parser.error("Bundled source checksum failed: " + relative)
        elif run(["git", "-C", localSource, "rev-parse", "HEAD"], capture=True).strip() != LIBTORRENT_COMMIT:
            parser.error("The supplied source checkout must be at the pinned libtorrent commit")

    if sourcePath.exists():
        if not marker.exists():
            parser.error(f"Incomplete prepared checkout at {sourcePath}; use a new --build-root")
        saved = json.loads(marker.read_text(encoding="utf-8"))
        if saved["recipe"] != recipe:
            parser.error("Prepared source manifest differs; use a new --build-root")
        baseline = saved.get("baseline_tree", "HEAD")
        currentDiff = run(["git", "-C", sourcePath, "diff", "--binary", baseline], capture=True)
        if hashlib.sha256(currentDiff.encode()).hexdigest() != saved["source_diff_sha256"]:
            parser.error("Prepared sources were changed after patching; use a new --build-root")
    else:
        baseline = "HEAD"
        if bundledManifest is not None:
            shutil.copytree(localSource, sourcePath)
            # Reconstruct an isolated index, not a commit, from the verified bundle.
            run(["git", "init", "--quiet", sourcePath])
            # Verified Windows exports can carry CRLF. Reconstruct the same LF
            # text blobs as the pinned repository before applying its patches.
            run(["git", "-C", sourcePath, "config", "core.autocrlf", "input"])
            run(["git", "-C", sourcePath, "add", "--force", "--all"])
            baseline = run(["git", "-C", sourcePath, "write-tree"], capture=True).strip()
            run(["git", "-C", sourcePath, "checkout-index", "--force", "--all"])
        elif localSource is not None:
            run(["git", "clone", "--no-hardlinks", "--no-checkout", localSource, sourcePath])
        else:
            run(["git", "clone", "--branch", "v" + LIBTORRENT_VERSION, "--depth", "1", "--no-checkout",
                 LIBTORRENT_REPOSITORY, sourcePath])
        if bundledManifest is None:
            run(["git", "-C", sourcePath, "config", "core.autocrlf", "false"])
            run(["git", "-C", sourcePath, "checkout", "--detach", LIBTORRENT_COMMIT])
            if run(["git", "-C", sourcePath, "rev-parse", "HEAD"], capture=True).strip() != LIBTORRENT_COMMIT:
                parser.error("The fetched tag does not match the pinned commit")
            run(["git", "-C", sourcePath, "submodule", "init"])
        if localSource is not None and bundledManifest is None:
            submodules = run(["git", "-C", sourcePath, "config", "--file", ".gitmodules",
                              "--get-regexp", r"submodule\..*\.path"], capture=True)
            for line in submodules.splitlines():
                key, relativePath = line.split(None, 1)
                localSubmodule = localSource / relativePath
                if (localSubmodule / ".git").exists():
                    run(["git", "-C", sourcePath, "config", key[:-5] + ".url", localSubmodule])
        if bundledManifest is None:
            run(["git", "-c", "protocol.file.allow=always", "-C", sourcePath,
                 "submodule", "update", "--init", "--recursive"])
        for patch in patches:
            run(["git", "-C", sourcePath, "apply", "--check", "--index", patch])
            run(["git", "-C", sourcePath, "apply", "--index", patch])
        currentDiff = run(["git", "-C", sourcePath, "diff", "--binary", baseline], capture=True)
        saved = {"recipe": recipe, "source_diff_sha256": hashlib.sha256(currentDiff.encode()).hexdigest()}
        if bundledManifest is not None:
            saved["baseline_tree"] = baseline
            saved["bundled_manifest_sha256"] = digestFile(localSource.parent / "libtorrent-source.json")
        marker.write_text(json.dumps(saved, indent=2) + "\n", encoding="utf-8")

    if bundledManifest is not None:
        if saved.get("bundled_manifest_sha256") != digestFile(localSource.parent / "libtorrent-source.json"):
            parser.error("Bundled provenance changed; use a new --build-root")
        submoduleStatus = "\n".join(" " + item["commit"] + " " + item["path"] for item in bundledManifest["submodules"])
    elif run(["git", "-C", sourcePath, "rev-parse", "HEAD"], capture=True).strip() != LIBTORRENT_COMMIT:
        parser.error("Prepared source HEAD changed; use a new --build-root")
    else:
        submoduleStatus = run(["git", "-C", sourcePath, "submodule", "status", "--recursive"], capture=True)
    if any(line and line[0] != " " for line in submoduleStatus.splitlines()):
        parser.error("A submodule is missing or does not match its pinned commit")

    # Append these options last so caller options cannot turn this into a system install or shared build.
    configure = ["cmake", "-S", sourcePath, "-B", buildPath, "-G", "Ninja"] + arguments.cmakeArg + [
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_CXX_STANDARD=20",
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
        "-DBUILD_SHARED_LIBS=OFF",
        "-Dstatic_runtime=OFF",
        "-Ddeprecated-functions=OFF",
        "-Dbuild_tests=OFF",
        "-Dbuild_examples=OFF",
        "-Dbuild_tools=OFF",
        "-Dgnutls=OFF",
        "-DCMAKE_INSTALL_LIBDIR=lib",
        "-DCMAKE_INSTALL_PREFIX=" + str(prefix),
    ]
    if os.name == "nt":
        configure.append("-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL")
    run(configure)
    run(["cmake", "--build", buildPath, "--parallel", arguments.jobs])
    run(["cmake", "--install", buildPath, "--prefix", prefix])
    cmakePackage = prefix / "lib" / "cmake" / "LibtorrentRasterbar"
    if not (cmakePackage / "LibtorrentRasterbarConfig.cmake").is_file():
        parser.error("The explicit static libtorrent CMake package was not installed")
    targets = (cmakePackage / "LibtorrentRasterbarTargets.cmake").read_text(encoding="utf-8")
    if "STATIC IMPORTED" not in targets:
        parser.error("The prepared libtorrent CMake target is not a static library")
    suffix = ".lib" if os.name == "nt" else ".a"
    archives = list((prefix / "lib").glob("*torrent-rasterbar*" + suffix))
    if len(archives) != 1:
        parser.error("Cannot identify the prepared static libtorrent archive")
    result = dict(recipe, variant=variant, source_dir=str(sourcePath), prefix=str(prefix),
                  cmake_package_dir=str(cmakePackage), submodules=submoduleStatus.splitlines(),
                  source_diff_sha256=saved["source_diff_sha256"], static_archive=str(archives[0]))
    arguments.result.parent.mkdir(parents=True, exist_ok=True)
    arguments.result.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print("Static libtorrent prepared: " + str(prefix), flush=True)


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError, ValueError, KeyError) as error:
        print("Preparing libtorrent failed: " + str(error), file=sys.stderr)
        sys.exit(1)
