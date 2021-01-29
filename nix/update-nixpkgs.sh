#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-git -I nixpkgs=channel:nixos-unstable-small

REV=refs/heads/nixos-unstable-small

nix-prefetch-git https://github.com/nixos/nixpkgs.git \
                 --rev "$REV" > ./nix/nixpkgs.json
