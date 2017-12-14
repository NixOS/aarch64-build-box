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

  ofborg = builtins.storePath ./nix/ofborg-path;

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

        trustedUsers = [ "@wheel" "@trusted" ];

        package = pkgs.nixUnstable;

        useSandbox = true;
      };
    })

    ({pkgs, ...}: {
      users.users.gc-of-borg = {
        description = "GC Of Borg Workers";
        home = "/var/lib/gc-of-borg";
        createHome = true;
        group = "gc-of-borg";
        uid = 402;
      };
      users.groups.gc-of-borg.gid = 402;

      systemd.services.grahamcofborg-builder = {
        enable = true;
        after = [ "network.target" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        path = with pkgs; [
          nixUnstable
          git
          curl
          bash
        ];

        serviceConfig = {
          User = "gc-of-borg";
          Group = "gc-of-borg";
          PrivateTmp = true;
          WorkingDirectory = "/var/lib/gc-of-borg";
          Restart = "always";
        };

        preStart = ''
          mkdir -p ./nix-test
        '';

        script = ''
          export HOME=/var/lib/gc-of-borg;
          export NIX_REMOTE=daemon;
          export NIX_PATH=nixpkgs=/run/current-system/nixpkgs;
          git config --global user.email "graham+cofborg@grahamc.com"
          git config --global user.name "GrahamCOfBorg"
          export RUST_BACKTRACE=1

          ${ofborg}/bin/builder /persist/ofborg/config.json
        '';
      };
    })

    ./users.nix
  ];
}
