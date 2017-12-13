{ pkgs ? import ./nix { system = "aarch64-linux"; }
}:
let
  makeNetboot = config:
    let
      config_evaled = import "${pkgs.path}/nixos/lib/eval-config.nix" config;
      build = config_evaled.config.system.build;
      kernelTarget = config_evaled.pkgs.stdenv.platform.kernelTarget;
    in
      pkgs.symlinkJoin {
        name="netboot";
        paths=[
          build.netbootRamdisk
          build.kernel
          build.netbootIpxeScript
        ];
        postBuild = ''
          mkdir -p $out/nix-support
          echo "file ${kernelTarget} $out/${kernelTarget}" >> $out/nix-support/hydra-build-products
          echo "file initrd $out/initrd" >> $out/nix-support/hydra-build-products
          echo "file ipxe $out/netboot.ipxe" >> $out/nix-support/hydra-build-products
        '';
      };

      persistence = pkgs.writeScript "persistence"
        ''
          #!/bin/sh

          set -eu
          set -o pipefail

          PATH="${pkgs.coreutils}/bin:${pkgs.eject}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.e2fsprogs}/bin"

          exec ${./persistence.sh}
        '';
in makeNetboot {
  system = "aarch64-linux";
  modules = [
    "${pkgs.path}/nixos/modules/installer/netboot/netboot-minimal.nix"

    { # Hardware Tuning
      boot = {
        initrd.availableKernelModules = [ "ahci" "pci_thunder_ecam" ];

        kernelParams = [
          "cma=0M" "biosdevname=0" "net.ifnames=0" "console=ttyAMA0" "initrd=initrd"
        ];
      };

      nix.maxJobs = 96;
      nixpkgs.system = "aarch64-linux";
    }

    ({lib, ...}: { # Overrides needed from the netboot-minimal.nix
      security.sudo.enable = lib.mkForce true;
      systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
      services.mingetty.autologinUser = lib.mkForce null;
    })

    ({pkgs, ...}: { # Config specific to this purpose
      boot.initrd.postMountCommands = "${persistence}";
      boot.postBootCommands = ''
        ls -la /
        rm /etc/ssh/ssh_host_*
        cp -r /persist/ssh/ssh_host_* /etc/ssh/
      '';

      nix = {
        gc = {
          automatic = true;
          options = "--max-freed $((64 * 1024**3))";
        };

        trustedUsers = [ "@wheel" ];

        package = pkgs.nixUnstable;

        useSandbox = true;
      };
    })

    ./users.nix
  ];
}
