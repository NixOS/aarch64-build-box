#!/bin/sh

set -eu
set -o pipefail

if [ "${1:-x}" = "x" ]; then
    ./nix/update-nixpkgs.sh
    ./nix/update-ofborg-path.sh
fi

cfgOpt() {
    ret=$(awk '$1 == "'"$1"'" { print $2; }' build.cfg)
    if [ -z "$ret" ]; then
        echo "Config option '$1' isn't specified in build.cfg" >&2
        echo "Example format:"
        echo "$1        value"
        echo ""
        exit 1
    fi

    echo "$ret"
}

buildHost=$(cfgOpt "buildHost")
target=$(cfgOpt "targetName")
pxeHost=$(cfgOpt "pxeHost")
pxeDir=$(cfgOpt "pxeDir")

tmpDir=$(mktemp -t -d nixos-rebuild-aarch-community.XXXXXX)
SSHOPTS="${NIX_SSHOPTS:-} -o ControlMaster=auto -o ControlPath=$tmpDir/ssh-%n -o ControlPersist=60"

cleanup() {
    for ctrl in "$tmpDir"/ssh-*; do
        ssh -o ControlPath="$ctrl" -O exit dummyhost 2>/dev/null || true
    done
    rm -rf "$tmpDir"
}
trap cleanup EXIT

set -eux

drv=$(nix-instantiate ./configuration.nix)
NIX_SSHOPTS=$SSHOPTS nix-copy-closure --to "$buildHost" "$drv"
out=$(ssh $SSHOPTS "$buildHost" NIX_REMOTE=daemon nix-store -r "$drv" -j 5)

ssh "$pxeHost" rm -rf "${pxeDir}/${target}"
ssh "$pxeHost" mkdir "${pxeDir}/${target}"
ssh -A "$buildHost" scp "$out/{Image,initrd,netboot.ipxe}" "${pxeHost}:${pxeDir}/${target}/"
