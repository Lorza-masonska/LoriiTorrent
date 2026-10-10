#!/bin/sh
set -eu

package_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir=${QBT_SOURCE:-upstream}
case "$source_dir" in
    /*) ;;
    *) source_dir="$package_root/$source_dir" ;;
esac

gui=${GUI:-ON}
testing=${TESTING:-ON}
jobs=${BUILD_JOBS:-2}
patches=${LIBTORRENT_PATCHES:-ON}
case "$gui:$testing" in
    ON:ON|ON:OFF|OFF:ON|OFF:OFF) ;;
    *) printf '%s\n' 'GUI and TESTING must be ON or OFF.' >&2; exit 2 ;;
esac
case "$patches" in
    ON|OFF) ;;
    *) printf '%s\n' 'LIBTORRENT_PATCHES must be ON or OFF.' >&2; exit 2 ;;
esac
case "$jobs" in
    ''|*[!0-9]*|0) printf '%s\n' 'BUILD_JOBS must be a positive integer.' >&2; exit 2 ;;
esac
if [ ! -f "$source_dir/CMakeLists.txt" ]; then
    printf 'Missing qBittorrent sources: %s\n' "$source_dir" >&2
    exit 2
fi

variant=gui
if [ "$gui" = OFF ]; then
    variant=nox
fi
libtorrent_result="$package_root/build/libtorrent-result-$patches.json"
python3 "$package_root/packaging/prepare-libtorrent.py" \
    --mode "$patches" --jobs "$jobs" --result "$libtorrent_result" \
    --build-root "${LIBTORRENT_BUILD_ROOT:-"$package_root/build"}" -- "$@"
libtorrent_package=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["cmake_package_dir"])' "$libtorrent_result")
libtorrent_variant=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["variant"])' "$libtorrent_result")
build_dir=${BUILD_DIR:-"$package_root/build/qbt-$variant-$libtorrent_variant"}
install_dir=${INSTALL_DIR:-"$package_root/build/packages/qbt-$variant-$libtorrent_variant"}
mkdir -p "$install_dir"
install_dir=$(CDPATH= cd -- "$install_dir" && pwd)

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    "$@" -DCMAKE_INSTALL_PREFIX=/usr \
    -DGUI="$gui" -DWEBUI=ON -DTESTING="$testing" \
    -DLibtorrentRasterbar_DIR="$libtorrent_package"
python3 "$package_root/packaging/verify-static-link.py" \
    --build-dir "$build_dir" --manifest "$libtorrent_result"
cmake --build "$build_dir" --parallel "$jobs"
if [ "$testing" = ON ]; then
    cmake --build "$build_dir" --target check --parallel "$jobs"
fi
DESTDIR="$install_dir" cmake --install "$build_dir"
mkdir -p "$install_dir/usr/share/doc/loriitorrent"
cp "$source_dir/COPYING" "$install_dir/usr/share/doc/loriitorrent/COPYING"
python3 "$package_root/packaging/public-manifest.py" "$libtorrent_result" "$install_dir/usr/share/doc/loriitorrent/libtorrent-build.json"
cp "$package_root/README.md" "$package_root/NOTICE.md" "$package_root/LICENSE" "$package_root/PROVENANCE.json" "$install_dir/usr/share/doc/loriitorrent/"
cp -R "$package_root/LICENSES" "$install_dir/usr/share/doc/loriitorrent/licenses"
if command -v dpkg-query >/dev/null 2>&1; then
    dpkg-query -W 'libboost*' 'libtorrent-rasterbar*' 'libqt6*' 'qt6-*' \
        'libssl*' 'zlib1g*' 'cmake' 'g++' 'ninja-build' \
        > "$install_dir/usr/share/doc/loriitorrent/dependency-versions.tsv" 2>/dev/null || true
fi
printf 'Package staged in %s\n' "$install_dir"
