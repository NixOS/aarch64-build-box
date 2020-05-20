#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-prefetch-git -I nixpkgs=channel:nixos-unstable-small

REV=refs/heads/nixos-20.03

nix-prefetch-git https://github.com/nixos/nixpkgs-channels.git \
                 --rev "$REV" > ./nix/nixpkgs.json
