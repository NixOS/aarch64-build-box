let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) lib;

  users = {
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
