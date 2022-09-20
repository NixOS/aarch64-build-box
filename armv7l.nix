{ config, pkgs, ... }:
{
  boot.kernelPatches = [
    rec {
      name = "compat_uts_machine";
      patch = pkgs.fetchpatch {
        inherit name;
        url = "https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/jammy/patch/?id=c1da50fa6eddad313360249cadcd4905ac9f82ea";
        sha256 = "sha256-mpq4YLhobWGs+TRKjIjoe5uDiYLVlimqWUCBGFH/zzU=";
      };
    }
  ];
  boot.kernelParams = [
    "compat_uts_machine=armv7l"
  ];
  nix.extraOptions = "extra-platforms = armv7l-linux";
}
