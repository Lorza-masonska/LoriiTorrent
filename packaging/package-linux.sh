#!/bin/sh
set -eu
umask 022

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    printf '%s\n' 'Usage: sh packaging/package-linux.sh <exported-GUI-stage> [output-directory]' >&2
    exit 2
fi
package_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
stage_dir=$(CDPATH= cd -- "$1" && pwd)
output_dir=${2:-"$package_root/build/releases"}
mkdir -p "$output_dir"
output_dir=$(CDPATH= cd -- "$output_dir" && pwd)
if [ ! -w "$output_dir" ]; then
    printf 'The packaging user must be able to write the output directory: %s\n' "$output_dir" >&2
    exit 2
fi
. /etc/os-release
if [ "$ID" != debian ] || [ "$VERSION_ID" != 13 ] || [ "$(dpkg --print-architecture)" != amd64 ]; then
    printf '%s\n' 'This package recipe requires Debian 13 amd64.' >&2
    exit 2
fi
for tool in dpkg-shlibdeps dpkg-deb python3; do
    command -v "$tool" >/dev/null 2>&1 || { printf 'Missing packaging tool: %s\n' "$tool" >&2; exit 2; }
done
if [ ! -f "$stage_dir/usr/bin/qbittorrent" ]; then
    printf '%s\n' 'The supplied stage must contain the GUI executable usr/bin/qbittorrent.' >&2
    exit 2
fi
manifest="$stage_dir/usr/share/doc/loriitorrent/libtorrent-build.json"
patch_mode=$(python3 -c 'import json,sys
data=json.load(open(sys.argv[1]))
if data.get("linkage")!="static" or data.get("version")!="2.0.15" or data.get("patch_mode") not in ("ON", "OFF"):
    raise SystemExit("Expected a static libtorrent 2.0.15 manifest with patch mode ON or OFF")
print(data["patch_mode"])' "$manifest")
version=${PACKAGE_VERSION:-5.2.4+loriitorrent.3-1}
dpkg --validate-version "$version"
deb_path="$output_dir/loriitorrent_${version}_amd64.deb"
tar_path="$output_dir/loriitorrent_${version}_amd64.tar.gz"
hash_path="$output_dir/loriitorrent_${version}_amd64.sha256"
if [ -e "$deb_path" ] || [ -e "$tar_path" ] || [ -e "$hash_path" ]; then
    printf '%s\n' 'Release output already exists; choose another PACKAGE_VERSION or output directory.' >&2
    exit 2
fi
work_root=$(mktemp -d "$output_dir/loriitorrent-package.XXXXXX")
binary_root="$work_root/binary"
scan_root="$work_root/dependency-scan"
mkdir -p "$binary_root" "$scan_root/debian" "$binary_root/DEBIAN"
mkdir -p "$binary_root/usr/lib/loriitorrent" "$binary_root/usr/bin" \
    "$binary_root/usr/share/applications" "$binary_root/usr/share/icons/hicolor/scalable/apps" \
    "$binary_root/usr/share/doc/loriitorrent"
cp "$stage_dir/usr/bin/qbittorrent" "$binary_root/usr/lib/loriitorrent/qbittorrent"
chmod 0755 "$binary_root/usr/lib/loriitorrent/qbittorrent"
cat > "$binary_root/usr/bin/loriitorrent" <<'LAUNCHER'
#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
for argument in "$@"; do
    case "$argument" in
        --profile=*) exec /usr/lib/loriitorrent/qbittorrent "$@" ;;
    esac
done
exec /usr/lib/loriitorrent/qbittorrent --profile="${XDG_CONFIG_HOME:-$HOME/.config}/LoriiTorrent" "$@"
LAUNCHER
chmod 0755 "$binary_root/usr/bin/loriitorrent"
cat > "$binary_root/usr/share/applications/loriitorrent.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=LoriiTorrent
GenericName=Klient BitTorrent
Comment=Klient BitTorrent z automatycznym wznawianiem webseedów
Exec=loriitorrent %U
Icon=loriitorrent
Terminal=false
Categories=Network;FileTransfer;P2P;Qt;
MimeType=application/x-bittorrent;x-scheme-handler/magnet;
StartupNotify=true
DESKTOP
cp "$package_root/upstream/src/icons/qbittorrent_mac.svg" "$binary_root/usr/share/icons/hicolor/scalable/apps/loriitorrent.svg"
printf 'Source: loriitorrent\nSection: net\nPriority: optional\nMaintainer: Local Builder <local@localhost>\n\nPackage: loriitorrent\nArchitecture: amd64\nDescription: Local qBittorrent GUI build with static libtorrent\n' > "$scan_root/debian/control"
depends=$(cd "$scan_root" && dpkg-shlibdeps -O -e"$binary_root/usr/lib/loriitorrent/qbittorrent")
depends=${depends#shlibs:Depends=}
dependency_versions="$stage_dir/usr/share/doc/loriitorrent/dependency-versions.tsv"
qt_version=$(python3 -c 'import sys; rows=[line.split() for line in open(sys.argv[1])]; print(next(row[1] for row in rows if row[0].split(":")[0]=="libqt6core6t64"))' "$dependency_versions")
qt_svg_version=$(python3 -c 'import sys; rows=[line.split() for line in open(sys.argv[1])]; print(next(row[1] for row in rows if row[0].split(":")[0]=="libqt6svg6"))' "$dependency_versions")
depends="$depends, libqt6core6t64 (>= $qt_version), libqt6sql6-sqlite (>= $qt_version), qt6-qpa-plugins (>= $qt_version), qt6-svg-plugins (>= $qt_svg_version), python3 (>= 3.11)"
doc_dir="$binary_root/usr/share/doc/loriitorrent"
mkdir -p "$doc_dir/source-patches" "$doc_dir/licenses"
python3 "$package_root/packaging/public-manifest.py" "$manifest" "$doc_dir/libtorrent-build.json"
cp "$dependency_versions" "$doc_dir/dependency-versions.tsv"
cp "$package_root/README.md" "$package_root/NOTICE.md" "$package_root/LICENSE" "$package_root/PROVENANCE.json" "$doc_dir/"
cp -R "$package_root/LICENSES/." "$doc_dir/licenses/"
cp "$package_root/packaging/third-party/libtorrent-2.0.15-LICENSE" "$doc_dir/licenses/"
cp -R "$package_root/packaging/third-party/libtorrent-2.0.15" "$doc_dir/licenses/"
cp /usr/share/doc/libboost1.83-dev/copyright "$doc_dir/licenses/boost-copyright"
for notice in AUTHORS COPYING.GPLv2 COPYING.GPLv3; do
    cp "$package_root/packaging/third-party/qbittorrent-5.2.4/$notice" "$doc_dir/"
done
cp "$package_root/packaging/third-party/qbittorrent-5.2.4/COPYING" "$doc_dir/copyright"
cp "$package_root/packaging/patches/"*.patch "$doc_dir/source-patches/"
for test_patch in "$package_root/packaging/"qbittorrent-*.patch; do
    if [ -f "$test_patch" ]; then
        cp "$test_patch" "$doc_dir/source-patches/"
    fi
done
cp "$package_root/packaging/RELEASE.md" "$doc_dir/RELEASE.md"
cp "$package_root/packaging/SOURCE.md" "$doc_dir/SOURCE.md"
installed_size=$(du -sk "$binary_root/usr" | cut -f1)
cat > "$binary_root/DEBIAN/control" <<EOF
Package: loriitorrent
Version: $version
Section: net
Priority: optional
Architecture: amd64
Maintainer: Local Builder <local@localhost>
Installed-Size: $installed_size
Depends: $depends
Description: LoriiTorrent - klient BitTorrent z automatycznym wznawianiem webseedow
 Otwarty fork qBittorrenta 5.2.4 z GUI, WebUI i statycznym libtorrent 2.0.15.
 Osobny profil i launcher; moze wspolistniec ze zwyklym qBittorrentem.
 Tryb poprawek silnika: $patch_mode. Manifest opisuje dokladny zestaw zmian.
EOF
chmod 0755 "$binary_root/DEBIAN"
chmod 0644 "$binary_root/DEBIAN/control"
dpkg-deb --root-owner-group --build "$binary_root" "$deb_path"
tar -C "$binary_root" --exclude='./DEBIAN' --owner=0 --group=0 --numeric-owner -czf "$tar_path" .
(cd "$output_dir" && sha256sum "$(basename "$deb_path")" "$(basename "$tar_path")") > "$hash_path"
printf 'Debian package: %s\nPortable staging archive: %s\n' "$deb_path" "$tar_path"
