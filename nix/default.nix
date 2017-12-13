let
  hostpkgs = import <nixpkgs> {};

  srcDef = builtins.fromJSON (builtins.readFile ./nixpkgs.json);

  inherit (hostpkgs) fetchFromGitHub fetchpatch fetchurl;
in import (hostpkgs.stdenv.mkDerivation {
  name = "aarch64-nixpkgs-${builtins.substring 0 10 srcDef.rev}";
  phases = [ "unpackPhase" "patchPhase" "moveToOut" ];

  src = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs-channels";
    inherit (srcDef) rev sha256;
  };

  patches = [
    (fetchurl {
      # aarch64 netboot patches
      url = "https://github.com/NixOS/nixpkgs/commit/08b8bc24cb818d78971f6cb941b7991e54c6971b.patch";
      sha256 = "0gzqx2wp6s5b6rkk4a9nqi3d9dx6bd0vc2i1sh2289z6dlghxzp0";
    })
  ];

  moveToOut = ''
    root=$(pwd)
    cd ..
    mv "$root" $out
  '';
})
