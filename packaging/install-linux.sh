#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
set -eu
task_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
task_package="$task_dir/loriitorrent_5.2.4+loriitorrent.3-1_amd64.deb"
if [ ! -f "$task_package" ]; then
    printf '%s\n' 'Umieść skrypt obok paczki loriitorrent_5.2.4+loriitorrent.3-1_amd64.deb.' >&2
    exit 2
fi
. /etc/os-release
if [ "$ID" != debian ] || [ "$VERSION_ID" != 13 ] || [ "$(dpkg --print-architecture)" != amd64 ]; then
    printf '%s\n' 'Ta paczka wymaga Debiana 13 amd64. Dla innego systemu wybierz Docker lub budowanie ze źródeł.' >&2
    exit 2
fi
if [ -f "$task_package.sha256" ]; then
    (cd "$task_dir" && sha256sum --check "$(basename "$task_package").sha256")
fi
sudo apt install "$task_package"
