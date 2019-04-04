let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) lib;

  users = {
    # 1. Generate an SSH key for your root account and add the public
    #    key to a file matching your name in ./keys/
    #
    # 2. Copy / paste this in order, alphabetically:
    #
    #    youruser = {
    #      trusted = true;
    #      keys = ./keys/youruser;
    #    };

    adisbladis = {
      trusted = true;
      keys = ./keys/adisbladis;
    };

    andir = {
      trusted = true;
      keys = ./keys/andir;
    };

    aszlig = {
      trusted = true;
      keys = keys/aszlig;
    };

    bennofs = {
      trusted = true;
      keys = ./keys/bennofs;
    };

    bkchr = {
      trusted = true;
      keys = ./keys/bkchr;
    };

    cstrahan = {
      trusted = true;
      keys = ./keys/cstrahan;
    };

    dezgeg = {
      trusted = true;
      keys = ./keys/dezgeg;
    };

    dhess = {
      trusted = true;
      keys = ./keys/dhess;
    };

    clever = {
      trusted = true;
      keys = ./keys/clever;
    };

    dtz = {
      trusted = true;
      keys = ./keys/dtz;
    };

    etu = {
      trusted = true;
      keys = ./keys/etu;
    };

    flokli = {
      trusted = true;
      keys = ./keys/flokli;
    };

    expipiplus1 = {
      trusted = true;
      keys = ./keys/expipiplus1;
    };

    globin = {
      trusted = true;
      keys = ./keys/globin;
    };

    grahamc = {
      sudo = true;
      trusted = true;
      password = "$6$lAjIm6PyElKewH$WfO/3pGei09YstCXghkCx5bDUvxsou2h63HMMTHgA/5tF8AsU6iw36PZm66z34n4oxW13yTUXaUAuKP/aHepg.";
      keys = ./keys/grahamc;
    };

    jtojnar = {
      trusted = true;
      keys = ./keys/jtojnar;
    };

    kamilchm = {
      trusted = true;
      keys = ./keys/kamilchm;
    };

    lheckemann = {
      sudo = true;
      trusted = true;
      keys = ./keys/lheckemann;
    };

    lnl = {
      trusted = true;
      keys = ./keys/lnl;
    };

    makefu = {
      trusted = true;
      keys = ./keys/makefu;
    };

    matthewbauer = {
      trusted = true;
      keys = ./keys/matthewbauer;
    };

    mic92 = {
      trusted = true;
      keys = ./keys/mic92;
    };

    mog = {
      trusted = true;
      keys = ./keys/mog;
    };

    moredread = {
      trusted = true;
      keys = ./keys/moredread;
    };

    moretea = {
      trusted = true;
      keys = ./keys/moretea;
    };

    Profpatsch = {
      trusted = true;
      keys = ./keys/Profpatsch;
    };

    rnhmjoj = {
      trusted = true;
      keys = ./keys/rnhmjoj;
    };

    samueldr = {
      sudo = true;
      trusted = true;
      keys = ./keys/samueldr;
    };

    tomberek = {
      trusted = true;
      keys = ./keys/tomberek;
    };

    vcunat = {
      trusted = true;
      keys = ./keys/vcunat;
    };

    volth = {
      trusted = true;
      keys = ./keys/volth;
    };

    willibutz = {
      trusted = true;
      keys = ./keys/willibutz;
    };

    xeji = {
      trusted = true;
      keys = ./keys/xeji;
    };

    yegortimoshenko = {
      trusted = true;
      keys = ./keys/yegortimoshenko;
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
