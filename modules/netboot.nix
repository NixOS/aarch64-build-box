# This module creates netboot media containing the given NixOS
# configuration.

{ config, lib, pkgs, ... }:

with lib;

{
  options = {

    netboot.storeContents = mkOption {
      example = literalExample "[ pkgs.stdenv ]";
      description = ''
        This option lists additional derivations to be included in the
        Nix store in the generated netboot image.
      '';
    };

  };

  config = rec {
    # Don't build the GRUB menu builder script, since we don't need it
    # here and it causes a cyclic dependency.
    boot.loader.grub.enable = false;

    # !!! Hack - attributes expected by other modules.
    environment.systemPackages = [ pkgs.grub2_efi ]
      ++ (if pkgs.stdenv.system == "aarch64-linux"
          then []
          else [ pkgs.grub2 pkgs.syslinux ]);
    system.boot.loader.kernelFile = pkgs.stdenv.platform.kernelTarget;

    boot.initrd.postDeviceCommands = ''
      PATH="${pkgs.e2fsprogs}/bin:$PATH"

      if ! test -b /dev/sda2; then
        sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
          o # clear the in memory partition table
          n # new partition
          p # primary partition
          1 # partition number 1
            # default - start at beginning of disk
          +500M # 500MB for /persist
          n # new partition
          p # primary partition
          2 # partition #2
            # default -- start at the end of partition #1
            # default, end at the end of the disk
          p # print the in-memory partition table
          w # write the partition table
          q # and we're done
      EOF
      fi

      if ! test -L /dev/disk/by-label/persist; then
        mkfs.ext4 -L persist /dev/sda1
      fi

      mkfs.ext4 -L root -F /dev/sda2
    '';

    fileSystems."/old-nix-store" =
      { fsType = "ext4";
        device = "../nix-store.ext4";
        options = [ "loop" ];
        neededForBoot = true;
      };

    fileSystems."/" =
      { fsType = "ext4";
        device = "/dev/disk/by-label/root";
      };

    fileSystems."/persist" =
      { fsType = "ext4";
        device = "/dev/disk/by-label/persist";
        neededForBoot = true;
      };

    boot.initrd.availableKernelModules = [ "ext4" ];

    boot.initrd.kernelModules = [ "loop" ];

    # Closures to be copied to the Nix store, namely the init
    # script and the top-level system configuration directory.
    netboot.storeContents =
      [ config.system.build.toplevel ];

    # Create the squashfs image that contains the Nix store.
    system.build.ext4Store = import "${pkgs.path}/nixos/lib/make-ext4-fs.nix" {
      inherit pkgs;
      storePaths = config.netboot.storeContents;
      volumeLabel = "NETBOOTEXT4";
    };


    # Create the initrd
    system.build.netbootRamdisk = pkgs.makeInitrd {
      inherit (config.boot.initrd) compressor;
      prepend = [ "${config.system.build.initialRamdisk}/initrd" ];

      contents =
        [ { object = config.system.build.ext4Store;
            symlink = "/nix-store.ext4";
          }
        ];
    };

    system.build.netbootIpxeScript = pkgs.writeTextDir "netboot.ipxe" ''
      #!ipxe
      kernel ${pkgs.stdenv.platform.kernelTarget} init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}
      initrd initrd
      boot
    '';

    boot.loader.timeout = 10;

    boot.postBootCommands =
      ''
        # After booting, register the contents of the Nix store
        # in the Nix database in the tmpfs.
        ${config.nix.package}/bin/nix-store --load-db < /nix/store/nix-path-registration

        # nixos-rebuild also requires a "system" profile and an
        # /etc/NIXOS tag.
        touch /etc/NIXOS
        ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      '';

  };

}
