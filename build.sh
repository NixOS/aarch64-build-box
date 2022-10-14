#!/usr/bin/env nix-shell
#!nix-shell -p gawk gnused -i bash -I nixpkgs=channel:nixos-unstable-small

set -eu
set -o pipefail

if [ "${1:-x}" = "x" ]; then
    ./nix/update-nixpkgs.sh
    ./nix/update-ofborg-path.sh
    git clone https://github.com/NixOS/equinix-metal-builders
    git -C equinix-metal-builders reset --hard 2e23403a85b121f8fb58b60ff399a8b0d19d84ce
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

#buildHost=$(cfgOpt "buildHost")
#target=$(cfgOpt "imageName")


nix-build -I nixpkgs=channel:nixos-unstable-small ./equinix-metal-builders/build-support/aarch64-setup.nix --out-link ./importer
./importer
buildHost=$(cat machines | grep aarch64 | grep big-parallel | cut -d' ' -f1 | head -n1)
printf "%s %s\n" \
       "$(echo "$buildHost" | cut -d@ -f2)" \
       "$(grep "$buildHost" machines | head -n1 | cut -d' ' -f8 | base64 -d)" > KnownHosts


#pxeHost=$(cfgOpt "pxeHost")
#pxeDir=$(cfgOpt "pxeDir")
#opensslServer=$(cfgOpt "opensslServer")
#opensslPort=$(cfgOpt "opensslPort")
target=nix-community-aarch64
pxeHost=netboot@netboot.gsc.io
pxeDir=/var/lib/nginx/netboot/webroot/
opensslServer=netboot.gsc.io
opensslPort=61616


tmpDir=$(mktemp -t -d nixos-rebuild-aarch-community.XXXXXX)
SSHOPTS="${NIX_SSHOPTS:-}  -o UserKnownHostsFile=$(pwd)/KnownHosts -o ControlMaster=auto -o ControlPath=$tmpDir/ssh-%n -o ControlPersist=60"

recvpid=0
cleanup() {
    for ctrl in "$tmpDir"/ssh-*; do
        ssh -o ControlPath="$ctrl" -O exit dummyhost 2>/dev/null || true
    done
    rm -rf "$tmpDir"

    if [ "$recvpid" -gt 0 ]; then
        kill -9 "$recvpid"
    fi
}
trap cleanup EXIT

set -eu

drv=$(nix-instantiate -I nixpkgs=channel:nixos-unstable-small ./configuration.nix --show-trace)
NIX_SSHOPTS=$SSHOPTS nix-copy-closure --use-substitutes --gzip --to "$buildHost" "$drv"
out=$(ssh $SSHOPTS "$buildHost" NIX_REMOTE=daemon nix-store --keep-going -r "$drv" -j 5 --cores 45 --add-root ./community-build-box --indirect)


ssh $SSHOPTS "$pxeHost" rm -rf "${pxeDir}/${target}.next"
ssh $SSHOPTS "$pxeHost" mkdir -p "${pxeDir}/${target}.next"

ssh $SSHOPTS "$buildHost" -- tar -C "$out" -hvvvczf - '{Image,initrd,netboot.ipxe}' \
    | ssh $SSHOPTS "$pxeHost" -- tar -C "${pxeDir}/${target}.next" -vvvzxf -

ssh $SSHOPTS "$pxeHost" mkdir -p "${pxeDir}/${target}"
ssh $SSHOPTS "$pxeHost" rm -rf "${pxeDir}/${target}.old"
ssh $SSHOPTS "$pxeHost" mv "${pxeDir}/${target}" "${pxeDir}/${target}.old"
ssh $SSHOPTS "$pxeHost" mv "${pxeDir}/${target}.next" "${pxeDir}/${target}"
