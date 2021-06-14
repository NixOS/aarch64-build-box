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

    "0x4A6F" = {
      trusted = true;
      keys = ./keys/0x4A6F;
    };

    aaronjanse = {
      trusted = true;
      keys = ./keys/aaronjanse;
    };

    adisbladis = {
      trusted = true;
      keys = ./keys/adisbladis;
    };

    amine = {
      trusted = true;
      keys = ./keys/amine;
    };

    andir = {
      trusted = true;
      keys = ./keys/andir;
    };

    angerman = {
      trusted = true;
      keys = ./keys/angerman;
    };

    aszlig = {
      trusted = true;
      keys = keys/aszlig;
    };

    bennofs = {
      trusted = true;
      keys = ./keys/bennofs;
    };

    betaboon = {
      trusted = true;
      keys = ./keys/betaboon;
    };

    bkchr = {
      trusted = true;
      keys = ./keys/bkchr;
    };

    blogle = {
      trusted = true;
      keys = ./keys/blogle;
    };

    cstrahan = {
      trusted = true;
      keys = ./keys/cstrahan;
    };

    danielfullmer = {
      trusted = true;
      keys = ./keys/danielfullmer;
    };

    dezgeg = {
      trusted = true;
      keys = ./keys/dezgeg;
    };

    dhess = {
      trusted = true;
      keys = ./keys/dhess;
    };

    domenkozar = {
      trusted = true;
      keys = ./keys/domenkozar;
    };

    clever = {
      trusted = true;
      keys = ./keys/clever;
    };

    craige = {
      trusted = true;
      keys = ./keys/craige;
    };

    colemickens = {
      trusted = true;
      keys = ./keys/colemickens;
    };

    dtz = {
      trusted = true;
      keys = ./keys/dtz;
    };

    ehmry = {
      trusted = true;
      keys = ./keys/ehmry;
    };

    etu = {
      trusted = true;
      keys = ./keys/etu;
    };

    fgaz = {
      trusted = true;
      keys = ./keys/fgaz;
    };

    flokli = {
      trusted = true;
      keys = ./keys/flokli;
    };

    fpletz = {
      trusted = true;
      keys = ./keys/fpletz;
    };

    expipiplus1 = {
      trusted = true;
      keys = ./keys/expipiplus1;
    };

    globin = {
      trusted = true;
      keys = ./keys/globin;
    };

    ghuntley = {
      trusted = true;
      keys = ./keys/ghuntley;
    };

    grahamc = {
      sudo = true;
      trusted = true;
      password = "$6$lAjIm6PyElKewH$WfO/3pGei09YstCXghkCx5bDUvxsou2h63HMMTHgA/5tF8AsU6iw36PZm66z34n4oxW13yTUXaUAuKP/aHepg.";
      keys = ./keys/grahamc;
    };

    izorkin = {
      trusted = true;
      keys = ./keys/izorkin;
    };

    jbaum98 = {
      trusted = true;
      keys = ./keys/jbaum98;
    };

    jtojnar = {
      trusted = true;
      keys = ./keys/jtojnar;
    };

    kalbasit = {
      trusted = true;
      keys = ./keys/kalbasit;
    };

    kamilchm = {
      trusted = true;
      keys = ./keys/kamilchm;
    };

    kiwi = {
      trusted = true;
      keys = ./keys/kiwi;
    };

    kloenk = {
      trusted = true;
      keys = ./keys/kloenk;
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

    lovesegfault = {
      trusted = true;
      keys = ./keys/lovesegfault;
    };

    ma27 = {
      trusted = true;
      keys = ./keys/ma27;
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

    nicoo = {
      trusted = true;
      keys = ./keys/nicoo;
    };

    Profpatsch = {
      trusted = true;
      keys = ./keys/Profpatsch;
    };

    prusnak = {
      trusted = true;
      keys = ./keys/prusnak;
    };

    qyliss = {
      trusted = true;
      keys = ./keys/qyliss;
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

    t184256 = {
      trusted = true;
      keys = ./keys/t184256;
    };

    timokau = {
      trusted = true;
      keys = ./keys/timokau;
    };

    tomberek = {
      trusted = true;
      keys = ./keys/tomberek;
    };

    tomfitzhenry = {
      trusted = true;
      keys = ./keys/tomfitzhenry;
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

    worldofpeace = {
      trusted = true;
      keys = ./keys/worldofpeace;
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
