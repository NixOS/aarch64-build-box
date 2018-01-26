#!/usr/bin/env nix-shell
#!nix-shell -p jq -p bash -p curl -p gawk --pure -i bash

set -eux
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

current_url=$(
    curl -X GET \
         --header 'Accept: application/json' \
         --header "X-Auth-Token: ${packetKey}" \
         "https://api.packet.net/devices/${packetDevice}" \
        | jq -r '.ipxe_script_url'
           );

if [ "${1:-x}" == "--force" ]; then
    current_url="...";
fi

if [ "$new_url" != "$current_url" ]; then
    curl --verbose -X PUT \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: ${packetKey}" \
         "https://api.packet.net/devices/${packetDevice}" \
         --data '{"ipxe_script_url": "'"$new_url"'"}'

    curl --verbose -X POST \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: ${packetKey}" \
         "https://api.packet.net/devices/${packetDevice}/actions" \
         --data '{"type": "reboot"}'

    echo "Previous Url: $current_url";
    echo "New Url: $new_url";
fi
