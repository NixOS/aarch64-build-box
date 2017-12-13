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

    flokli = {
      trusted = true;

      keys = ./keys/flokli;
    };

    grahamc = {
      trusted = true;

      keys = ./keys/grahamc;
    };

    vcunat = {
      trusted = true;

      keys = ./keys/vcunat;
    };
  };

  descToUser = name: opts:
    {
      isNormalUser = true;
      extraGroups = lib.optional opts.trusted "wheel";
      createHome = true;
      home = "/home/${name}";
      inherit (opts) hashedPassword;
      openssh.authorizedKeys.keyFiles = [
        opts.keys
      ];
    };
in {
  users = {
    mutableUsers = false;
    users = lib.mapAttrs descToUser users;
  };
}
