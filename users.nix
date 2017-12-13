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

    andir = {
      trusted = true;
      hashedPassword = "$6$V3ZUkVUFboRkt1eV$mF9UAu8hKHGRiRa/uQ.B5tA/whrdPDvP.bPibqXQqGrEI.F5K9ga5NdePxWSF1zfju3HseEZ6GlSaIumIDSCc0";
      keys = ./keys/andir;
    };

    dezgeg = {
      trusted = true;

      keys = ./keys/dezgeg;
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
