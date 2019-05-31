#!/usr/bin/env nix-shell
#!nix-shell -p jq -p bash -p curl -p gawk --pure -i bash

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

pxeUrlPrefix=$(cfgOpt "pxeUrlPrefix")
pxeUrlSuffix=$(cfgOpt "pxeUrlSuffix")
imageName=$(cfgOpt "imageName")
pxeDir=$(cfgOpt "pxeDir")
packetKey=$(cfgOpt "packetKey")
packetDevice=$(cfgOpt "packetDevice")

new_url=${pxeUrlPrefix}/${imageName}/${pxeUrlSuffix}

curl -X PUT \
     --header 'Content-Type: application/json' \
     --header "X-Auth-Token: ${packetKey}" \
     "https://api.packet.net/devices/${packetDevice}" \
     --data '{"ipxe_script_url": "'"$new_url"'"}'

curl -X POST \
     --header 'Content-Type: application/json' \
     --header "X-Auth-Token: ${packetKey}" \
     "https://api.packet.net/devices/${packetDevice}/actions" \
     --data '{"type": "reboot"}'

echo "Rebooting...";
