#!/usr/bin/env nix-shell
#!nix-shell -p jq -p bash -p curl -p gawk -p cacert -i bash -I nixpkgs=channel:nixos-unstable-small

set -eu
set -o pipefail

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

packetDevice="956d80d8-21ba-476d-9b5c-d076b7f51329"
if [ "${PACKET_AUTH_TOKEN:-x}" == "x" ]; then
    PACKET_AUTH_TOKEN=$(cfgOpt "packetKey")
fi

curl -X POST \
     --header 'Content-Type: application/json' \
     --header "X-Auth-Token: ${PACKET_AUTH_TOKEN}" \
     "https://api.packet.net/devices/${packetDevice}/actions" \
     --data '{"type": "reboot"}'

echo "Rebooting...";
