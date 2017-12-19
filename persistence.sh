#!/bin/sh

set -eux
set -o pipefail

root=/mnt-root

if ! test -b /dev/sda1; then
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
      o # clear the in memory partition table
      n # new partition
      p # primary partition
      1 # partition number 1
        # default - start at beginning of disk
        # default, extend partition to end of disk
      p # print the in-memory partition table
      w # write the partition table
      q # and we're done
EOF
fi

if ! test -L /dev/disk/by-label/persist; then
    mkfs.ext4 -L persist /dev/sda1
fi

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
