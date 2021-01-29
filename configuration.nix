{ pkgs ? import ./nix { system = "aarch64-linux"; }
}:
let
  makeNetboot = config:
    let
      config_evaled = import "${pkgs.path}/nixos/lib/eval-config.nix" config;
      build = config_evaled.config.system.build;
      kernelTarget = config_evaled.pkgs.stdenv.hostPlatform.linux-kernel.target;
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

  postDeviceCommands = pkgs.writeScript "post-device-commands"
    ''
      #!/bin/sh

      set -eu
      set -o pipefail

      PATH="${pkgs.coreutils}/bin:${pkgs.utillinux}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.e2fsprogs}/bin:${pkgs.zfs}/bin"

      exec ${./post-devices.sh}
    '';

  postMountCommands = pkgs.writeScript "post-mount-commands"
    ''
      #!/bin/sh

      set -eu
      set -o pipefail

      PATH="${pkgs.coreutils}/bin:${pkgs.utillinux}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.e2fsprogs}/bin"

      exec ${./persistence.sh}
    '';

  ofborg = builtins.storePath ./nix/ofborg-path;

in makeNetboot {
  system = "aarch64-linux";
  modules = [
    "${pkgs.path}/nixos/modules/profiles/all-hardware.nix"
    "${pkgs.path}/nixos/modules/profiles/minimal.nix"

    ./modules/netboot.nix

    ({ pkgs, config, ...}: { # Hardware Tuning
      boot = {
        consoleLogLevel = 7;
        initrd.availableKernelModules = [ "ahci" "hisi-rng" ];

        kernelParams = [
          "cma=0M" "biosdevname=0" "net.ifnames=0" "console=ttyAMA0,115200"
          "initrd=initrd"
        ];
        kernelPackages = pkgs.linuxPackages;
        #
        kernel.sysctl."kernel.hostname" = "${config.networking.hostName}.${config.networking.domain}";
      };

      nix.nrBuildUsers = config.nix.maxJobs * 2;
      nix.maxJobs = 64;
      nixpkgs.system = "aarch64-linux";
    })

    ({ # Go fast: networking
      networking.hostName = "aarch64";
      networking.domain = "nixos.community";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "147.75.77.189";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:0:d600::6";
        interface = "bond0";
      };
      networking.nameservers = [
        "147.75.207.207"
        "147.75.207.208"
      ];

      networking.bonds.bond0 = {
        driverOptions = {
          mode = "802.3ad";
          xmit_hash_policy = "layer3+4";
          lacp_rate = "fast";
          downdelay = "200";
          miimon = "100";
          updelay = "200";
        };
        interfaces = [
          "eth2" "eth3"
        ];
      };

      networking.interfaces.bond0 = {
        useDHCP = false;
        macAddress = "14:30:04:ea:87:26";

        ipv4 = {
          routes = [
            {
              address = "10.0.0.0";
              prefixLength = 8;
              via = "10.99.98.134";
            }
          ];
          addresses = [
            {
              address = "147.75.77.190";
              prefixLength = 30;
            }
            {
              address = "10.99.98.135";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:0:d600::7";
              prefixLength = 127;
            }
          ];
        };
      };
    })

    ({pkgs, ...}: { # Config specific to this purpose
      services.openssh = {
        enable = true;
        challengeResponseAuthentication = false;
        passwordAuthentication = false;
        extraConfig = ''
          MaxSessions 65
        '';
      };
      security.sudo.wheelNeedsPassword = false;

      boot.supportedFilesystems = [ "zfs" ];
      boot.initrd.postDeviceCommands = "${postDeviceCommands}";
      boot.initrd.postMountCommands = "${postMountCommands}";
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
            RestartSec = "10s";
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

        makeNBuilders = count:
          let
            toMake = pkgs.lib.range 1 count;
            services = map
              (n: { "grahamcofborg-builder-${toString n}" = builder (toString n); })
              toMake;
          in pkgs.lib.foldr (x: y: x // y) {} services;
      in makeNBuilders 16;
    })

    ({ pkgs, ... }: {
      systemd.services.clone-nixpkgs = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          ${pkgs.git}/bin/git clone --bare https://github.com/nixos/nixpkgs /tmp/nixpkgs.git
        '';
      };
    })

    ./users.nix
    ./monitoring.nix
    ./motd.nix
  ];
}
