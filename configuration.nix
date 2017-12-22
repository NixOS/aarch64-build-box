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
    "${pkgs.path}/nixos/modules/profiles/all-hardware.nix"
    "${pkgs.path}/nixos/modules/profiles/minimal.nix"

    ./modules/netboot.nix

    { # Hardware Tuning
      boot = {
        initrd.availableKernelModules = [ "ahci" "pci_thunder_ecam" ];

        kernelParams = [
          "cma=0M" "biosdevname=0" "net.ifnames=0" "console=ttyAMA0"
          "initrd=initrd"
        ];
      };

      nix.maxJobs = 96;
      nixpkgs.system = "aarch64-linux";
    }

    ({pkgs, ...}: { # Config specific to this purpose
      services.openssh.enable = true;

      boot.initrd.postMountCommands = "${persistence}";
      boot.postBootCommands = ''
        ls -la /
        rm /etc/ssh/ssh_host_*
        cp -r /persist/ssh/ssh_host_* /etc/ssh/
      '';

      systemd.services.nix-daemon = {
        environment.LD_PRELOAD = "${pkgs.libeatmydata}/lib/libeatmydata.so";
      };

      nix = {
        buildCores = 0;

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
      nix = {
        nixPath = [
          # Ruin the config so we don't accidentally run
          # nixos-rebuild switch on the host
          (let
            cfg = pkgs.writeText "configuration.nix"
              ''
                assert builtins.trace "Hey dummy, you're on your server! Use NixOps!" false;
                {}
              '';
           in "nixos-config=${cfg}")

           # Copy the channel version from the deploy host to the target
           "nixpkgs=/run/current-system/nixpkgs"
        ];
      };

      system.extraSystemBuilderCmds = ''
        ln -sv ${pkgs.path} $out/nixpkgs
      '';
      environment.etc.host-nix-channel.source = pkgs.path;
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

      systemd.services = let
        builder = id: {
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
            mkdir -p ./nix-test-rs-${id}
          '';

          script = ''
            export HOME=/var/lib/gc-of-borg;
            export NIX_REMOTE=daemon;
            export NIX_PATH=nixpkgs=/run/current-system/nixpkgs;
            git config --global user.email "graham+cofborg@grahamc.com"
            git config --global user.name "GrahamCOfBorg"
            export RUST_BACKTRACE=1

            ${ofborg}/bin/builder /persist/ofborg/config-${id}.json
          '';
        };
      in {
        grahamcofborg-builder-1 = builder "1";
        grahamcofborg-builder-2 = builder "2";
        grahamcofborg-builder-3 = builder "3";
      };
    })

    ./users.nix
  ];
}
