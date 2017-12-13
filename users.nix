let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) lib;

  users = {
    # 1. Generate a hashed password with:
    #
    # $ nix-shell -p mkpasswd --run "mkpasswd -m sha-512"
    #
    # 2. Generate an SSH key for your root account and add the public
    #    key to a file matching your name in ./keys/
    #
    # 3. Copy / paste this in order, alphabetically:
    #
    #    youruser = {
    #      trusted = true;
    #      hashedPassword = "a-hashed-password";
    #      keys = ./keys/youruser;
    #    };

    dezgeg = {
      trusted = true;
      keys = ./keys/dezgeg;
    };

    grahamc = {
      sudo = true;
      trusted = true;
      keys = ./keys/grahamc;
    };

    vcunat = {
      trusted = true;
      keys = ./keys/vcunat;
    };
  };

  ifAttr = key: default: result: opts:
    if (opts ? "${key}") && opts."${key}"
      then result
      else default;

  maybeTrusted = ifAttr "trusted" [] [ "trusted" ];
  maybeWheel = ifAttr "sudo" [] [ "wheel" ];

  userGroups = opts:
    (maybeTrusted opts) ++
    (maybeWheel opts);

  descToUser = name: opts:
    {
      isNormalUser = true;
      extraGroups = userGroups opts;
      createHome = true;
      home = "/home/${name}";
      hashedPassword = opts.password or null;
      openssh.authorizedKeys.keyFiles = [
        opts.keys
      ];
    };
in {
  users = {
    groups.trusted = {};

    mutableUsers = false;
    users = lib.mapAttrs descToUser users;
  };
}
