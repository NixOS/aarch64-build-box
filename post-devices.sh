#!/bin/sh

set -eux
set -o pipefail

if ! test -b /dev/sda1; then
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
      o # clear the in memory partition table
      n # new partition
      p # primary partition
      1 # partition number 1
        # default - start at beginning of disk
      +100M  # default, extend partition to end of disk
      n # new partition
      p # primary partition
      2 # partition number 2
        # default start
        # default end
      p # print the in-memory partition table
      w # write the partition table
      q # and we're done
EOF
fi

if ! test -L /dev/disk/by-label/persist; then
    mkfs.ext4 -L persist /dev/sda1
fi

if ! test -L /dev/disk/by-label/scratch-space; then
    mkfs.ext4 -L scratch-space /dev/sda2
fi

# Always erase the scratch space
mkfs.ext4 -F -L scratch-space /dev/disk/by-label/scratch-space
