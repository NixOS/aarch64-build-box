#!/bin/sh

set -eux
set -o pipefail

root=/mnt-root

mkdir -p $root/nix/store
chown 0:30000 $root/nix/store
rsync -a $root/old-nix-store $root/nix/store

umount $root/old-nix-store

mkdir -p "$root/persist"
chown 0:0 "$root/persist"
chmod 0711 "$root/persist"



mkdir -p "$root/persist/ssh"
chmod 0751 "$root/persist/ssh"
