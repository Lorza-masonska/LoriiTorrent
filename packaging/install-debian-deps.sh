#!/bin/sh
set -eu

# Verified Debian 13 packages. OpenSSL and other system packages receive security updates.
qt_base_version=${QT_BASE_PACKAGE_VERSION:-6.8.2+dfsg-9+deb13u2}
qt_tools_version=${QT_TOOLS_PACKAGE_VERSION:-6.8.2-5}
qt_svg_version=${QT_SVG_PACKAGE_VERSION:-6.8.2-3}
boost_version=${BOOST_PACKAGE_VERSION:-1.83.0-4.2}
gui=${GUI:-ON}
case "$gui" in
    ON|OFF) ;;
    *) printf '%s\n' 'GUI must be ON or OFF.' >&2; exit 2 ;;
esac
if [ "$(id -u)" != 0 ]; then
    printf '%s\n' 'Run this dependency installer as root on Debian 13.' >&2
    exit 2
fi
. /etc/os-release
if [ "$ID" != debian ] || [ "$VERSION_ID" != 13 ]; then
    printf '%s\n' 'This dependency installer requires Debian 13 (trixie).' >&2
    exit 2
fi

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential ca-certificates cmake ninja-build pkgconf python3 git libssl-dev zlib1g-dev \
    "libboost1.83-dev=$boost_version" \
    "qt6-base-dev=$qt_base_version" \
    "qt6-base-private-dev=$qt_base_version" \
    "libqt6sql6-sqlite=$qt_base_version" \
    "qt6-tools-dev=$qt_tools_version" \
    "qt6-tools-dev-tools=$qt_tools_version"
if [ "$gui" = ON ]; then
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        "qt6-svg-dev=$qt_svg_version" "qt6-svg-plugins=$qt_svg_version" \
        qt6-image-formats-plugins
fi
