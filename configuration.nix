{ pkgs, modulesPath, lib, ... }: {
  imports = [
    (modulesPath + "/profiles/all-hardware.nix")
    (modulesPath + "/profiles/minimal.nix")

    ({ pkgs, config, ...}: { # Hardware Tuning
      boot = {
        consoleLogLevel = 7;
        initrd.availableKernelModules = [ "ahci" "hisi-rng" ];

        kernelParams = [
          "cma=0M" "biosdevname=0" "net.ifnames=0" "console=ttyAMA0,115200"
          "initrd=initrd"
        ];
        kernelPackages = pkgs.linuxPackages_5_15;
        #
        kernel.sysctl."kernel.hostname" = "${config.networking.hostName}.${config.networking.domain}";
      };

      nix.nrBuildUsers = config.nix.settings.max-jobs * 2;
      nix.settings.max-jobs = 64;
      nixpkgs.system = "aarch64-linux";
    })

    ({ # Go fast: networking
      networking.hostName = "aarch64";
      networking.domain = "nixos.community";
      networking.dhcpcd.enable = false;
      networking.defaultGateway = {
        address = "147.28.143.249";
        interface = "bond0";
      };
      networking.defaultGateway6 = {
        address = "2604:1380:4641:c900::e";
        interface = "bond0";
      };
      networking.nameservers = [
        "147.75.207.207"
        "147.75.207.208"
      ];

      networking.firewall.logRefusedConnections = false;

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
              via = "10.70.108.142";
            }
          ];
          addresses = [
            {
              address = "147.28.143.250";
              prefixLength = 30;
            }
            {
              address = "10.70.108.143";
              prefixLength = 31;
            }
          ];
        };

        ipv6 = {
          addresses = [
            {
              address = "2604:1380:4641:c900::f";
              prefixLength = 127;
            }
          ];
        };
      };
    })

    ({pkgs, ...}: { # Config specific to this purpose
      services.openssh = {
        enable = true;
        settings.KbdInteractiveAuthentication = false;
        settings.PasswordAuthentication = false;
        extraConfig = ''
          MaxSessions 65
        '';
      };
      security.sudo.wheelNeedsPassword = false;

      boot.initrd.postDeviceCommands = "${pkgs.writeScript "post-device-commands" ''
        #!/bin/sh

        set -eu
        set -o pipefail

        PATH="${pkgs.coreutils}/bin:${pkgs.util-linux}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.e2fsprogs}/bin:${pkgs.btrfs-progs}/bin:${pkgs.kmod}/bin"

        exec ${./post-devices.sh}
      ''}";

      services.openssh.hostKeys = [
        { path = "/persist/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
        { path = "/persist/ssh/ssh_host_rsa_key"; type = "rsa"; }
      ];

      environment.systemPackages = [
        pkgs.git
      ];

      systemd.services.nix-daemon = {
        environment.LD_PRELOAD = "${pkgs.libeatmydata}/lib/libeatmydata.so";
      };

      nix = {
        gc = {
          automatic = true;
          options = "--max-freed $((64 * 1024**3))";
        };

        settings = {
          cores = 0;
          experimental-features = [ "flakes" "nix-command" ];
          sandbox = true;
          trusted-users = [ "@wheel" "@trusted" ];
        };
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

    {
      options.ofborg.package = lib.mkOption {
        description = "Ofborg package";
        type = lib.types.package;
      };
    }
    ({pkgs, config, ...}: {
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
            nix
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

            ${config.ofborg.package}/bin/builder /persist/ofborg/config-${id}.json
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
        startAt = "daily";
        script = ''
          if [ ! -d /tmp/nixpkgs.git ]; then
            ${pkgs.git}/bin/git clone --bare https://github.com/nixos/nixpkgs /tmp/nixpkgs.git
          fi
        '';
      };
    })

    ({ config, modulesPath, lib, pkgs, ... }: {
      fileSystems."/" = {
        fsType = "btrfs";
        label = "root";
        options = ["compress=lzo" "noatime" "discard=async"];
      };
      fileSystems."/persist" = {
        fsType = "ext4";
        label = "persist";
        neededForBoot = true;
      };
      boot.loader.grub.enable = false;
      system.build.bootStage2 = lib.mkForce config.system.build.bootStage1;
      boot.kernelParams = let
        stage2module = import (modulesPath + "/system/boot/stage-2.nix") {
          inherit config lib pkgs;
        };
        stage2Init = pkgs.runCommand "init.sh" {} ''
          substitute ${stage2module.config.system.build.bootStage2} $out \
            --replace-fail 'systemConfig=@systemConfig@' '
              for o in $(</proc/cmdline); do
                case $o in
                  rdinit=*)
                    set -- $(IFS==; echo $o)
                    rdinit=$2
                    ;;
                  *)
                    ;;
                esac
              done
              systemConfig=''${rdinit%/init}
            '
            chmod +x $out
        '';
      in [
        "boot.trace"
        "init=${stage2Init}"
        "boot.shell_on_fail"
      ];
      boot.postBootCommands = ''
        # nixos-rebuild also requires a "system" profile and an
        # /etc/NIXOS tag.
        touch /etc/NIXOS
        /nix/.nix-netboot-serve-db/register
        ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system
      '';
      boot.initrd.preDeviceCommands = ''
        ln -s ${config.system.modulesTree}/lib /lib
      '';
      system.build.initialRamdisk = lib.mkForce (pkgs.writeText "initrd" "not really :)))");
    })

    ./users.nix
    ./monitoring.nix
    ./motd.nix
    ./armv7l.nix
  ];
}
