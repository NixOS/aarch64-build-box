#!/usr/bin/env nix-shell
#!nix-shell -p gawk -i bash

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
target=$(cfgOpt "imageName")
pxeHost=$(cfgOpt "pxeHost")
pxeDir=$(cfgOpt "pxeDir")
opensslServer=$(cfgOpt "opensslServer")
opensslPort=$(cfgOpt "opensslPort")

tmpDir=$(mktemp -t -d nixos-rebuild-aarch-community.XXXXXX)
SSHOPTS="${NIX_SSHOPTS:-} -o ControlMaster=auto -o ControlPath=$tmpDir/ssh-%n -o ControlPersist=60"

cleanup() {
    for ctrl in "$tmpDir"/ssh-*; do
        ssh -o ControlPath="$ctrl" -O exit dummyhost 2>/dev/null || true
    done
    rm -rf "$tmpDir"
}
trap cleanup EXIT

set -eu

drv=$(nix-instantiate ./configuration.nix --show-trace)
NIX_SSHOPTS=$SSHOPTS nix-copy-closure --to "$buildHost" "$drv"
out=$(ssh $SSHOPTS "$buildHost" NIX_REMOTE=daemon nix-store --keep-going -r "$drv" -j 5 --cores 45)

psk=$(head -c 9000 /dev/urandom | md5sum | awk '{print $1}')

ssh "$pxeHost" rm -rf "${pxeDir}/${target}.old"
ssh "$pxeHost" mv "${pxeDir}/${target}" "${pxeDir}/${target}.old"
ssh "$pxeHost" -- nix-shell -p mbuffer openssl --run \
    "openssl s_server -nocert -naccept 1 \
         -psk $psk -accept ${opensslPort} \
       | mbuffer | tar -C ${pxeDir}/${target} -zx"
ssh $SSHOPTS "$buildhost" -- nix-shell -p mbuffer openssl --run \
    "tar -cf $out/{Image,initrd,netboot.ipxe} \
       | mbuffer | openssl s_client -psk $psk \
           -connect ${opensslServer}:${opensslPort}"
