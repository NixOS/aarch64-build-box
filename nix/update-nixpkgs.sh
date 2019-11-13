#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-git

REV=refs/heads/nixos-19.09

nix-prefetch-git https://github.com/nixos/nixpkgs-channels.git \
                 --rev "$REV" > ./nix/nixpkgs.json
