#!/usr/bin/env nix-shell
#!nix-shell -p curl -p jq -i bash

set -o pipefail
set -eu

ofborg=$(curl \
             -L -H "Content-Type: application/json" \
             https://hydra.nixos.org/job/ofborg/release/ofborg.rs.aarch64-linux/latest \
             | jq -r .buildoutputs.out.path)

nix-store --add-root ./nix/ofborg-path --indirect -r "$ofborg"
