#!/usr/bin/env nix-shell
#!nix-shell -p gawk gnused -i bash

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

drv=$(nix-instantiate ./configuration.nix --show-trace)
NIX_SSHOPTS=$SSHOPTS nix-copy-closure --to "$buildHost" "$drv"
out=$(ssh $SSHOPTS "$buildHost" NIX_REMOTE=daemon nix-store --keep-going -r "$drv" -j 5 --cores 45)

psk=$(head -c 9000 /dev/urandom | md5sum | awk '{print $1}')



ssh $SSHOPTS "$pxeHost" rm -rf "${pxeDir}/${target}.next"
ssh $SSHOPTS "$pxeHost" mkdir -p "${pxeDir}/${target}.next"
ssh $SSHOPTS "$pxeHost" -- nix-shell -p mbuffer openssl --run ":"


(ssh $SSHOPTS "$pxeHost" -- nix-shell -p mbuffer openssl --run \
    "'nc -4 -l ${opensslPort} | openssl enc -aes-256-cbc -d -k ${psk}  \
       | mbuffer | tar -C ${pxeDir}/${target}.next -vvvzxf -'" 2>&1 \
    | sed -e 's/^/RECV /')&

while ! ssh $SSHOPTS "$pxeHost" -- "ss -lnt | grep '${opensslPort}'"; do
    echo "Not listening"
    sleep 1
done
sleep 1

ssh $SSHOPTS "$buildHost" -- nix-shell -p pv mbuffer openssl --run \
    "'tar -C $out -hvvvczf - {Image,initrd,netboot.ipxe} \
       | mbuffer | openssl enc -aes-256-cbc -e -k $psk \
           | nc -N -4 ${opensslServer} ${opensslPort}'" 2>&1 \
    | sed -e 's/^/SEND /'

ssh $SSHOPTS "$pxeHost" mkdir -p "${pxeDir}/${target}"
ssh $SSHOPTS "$pxeHost" rm -rf "${pxeDir}/${target}.old"
ssh $SSHOPTS "$pxeHost" mv "${pxeDir}/${target}" "${pxeDir}/${target}.old"
ssh $SSHOPTS "$pxeHost" mv "${pxeDir}/${target}.next" "${pxeDir}/${target}"
