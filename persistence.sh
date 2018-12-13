#!/bin/sh

set -eux
set -o pipefail

root=/mnt-root

mkdir -p "$root/persist"
chown 0:0 "$root/persist"
chmod 0711 "$root/persist"

if ! mount | grep -q "$root/persist"; then
    mount /dev/disk/by-label/persist "$root/persist"
fi

chown 0:0 "$root/persist"
chmod 0711 "$root/persist"

mkdir -p "$root/persist/ssh"
chmod 0751 "$root/persist/ssh"
