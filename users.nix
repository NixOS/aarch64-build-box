{ lib, ... }:
let
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

    adamcstephens = {
      trusted = true;
      keys = ./keys/adamcstephens;
    };

    adisbladis = {
      trusted = true;
      keys = ./keys/adisbladis;
    };

    ajs124 = {
      trusted = true;
      keys = ./keys/ajs124;
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

    artturin = {
      trusted = true;
      keys = ./keys/artturin;
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

    cole-h = {
      sudo = true;
      trusted = true;
      keys = ./keys/cole-h;
    };

    cstrahan = {
      trusted = true;
      keys = ./keys/cstrahan;
    };

    dandellion = {
      trusted = true;
      keys = ./keys/dandellion;
    };

    danielfullmer = {
      trusted = true;
      keys = ./keys/danielfullmer;
    };

    davidak = {
      trusted = true;
      keys = ./keys/davidak;
    };

    delroth = {
      sudo = true;
      trusted = true;
      keys = ./keys/delroth;
    };

    dezgeg = {
      trusted = true;
      keys = ./keys/dezgeg;
    };

    dguibert = {
      trusted = true;
      keys = ./keys/dguibert;
    };

    dhess = {
      trusted = true;
      keys = ./keys/dhess;
    };

    domenkozar = {
      trusted = true;
      keys = ./keys/domenkozar;
    };

    dotlambda = {
      trusted = true;
      keys = ./keys/dotlambda;
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

    emily = {
      trusted = true;
      keys = ./keys/emily;
    };

    enzime = {
      trusted = true;
      keys = ./keys/enzime;
    };

    etu = {
      trusted = true;
      keys = ./keys/etu;
    };

    eyjhb = {
      trusted = true;
      keys = ./keys/eyjhb;
    };

    fab = {
      trusted = true;
      keys = ./keys/fab;
    };

    fgaz = {
      trusted = true;
      keys = ./keys/fgaz;
    };

    figsoda = {
      trusted = true;
      keys = ./keys/figsoda;
    };

    flokli = {
      trusted = true;
      keys = ./keys/flokli;
    };

    fpletz = {
      trusted = true;
      keys = ./keys/fpletz;
    };

    fsagbuya = {
      trusted = true;
      keys = ./keys/fsagbuya;
    };

    emilytrau = {
      trusted = true;
      keys = ./keys/emilytrau;
    };

    expipiplus1 = {
      trusted = true;
      keys = ./keys/expipiplus1;
    };

    gaelan = {
      trusted = true;
      keys = ./keys/gaelan;
    };

    globin = {
      trusted = true;
      keys = ./keys/globin;
    };

    ghuntley = {
      trusted = true;
      keys = ./keys/ghuntley;
    };

    glepage = {
      trusted = true;
      keys = ./keys/glepage;
    };

    grahamc = {
      sudo = true;
      trusted = true;
      password = "$6$lAjIm6PyElKewH$WfO/3pGei09YstCXghkCx5bDUvxsou2h63HMMTHgA/5tF8AsU6iw36PZm66z34n4oxW13yTUXaUAuKP/aHepg.";
      keys = ./keys/grahamc;
    };

    hexa = {
      trusted = true;
      keys = ./keys/hexa;
    };

    izorkin = {
      trusted = true;
      keys = ./keys/izorkin;
    };

    jade = {
      trusted = true;
      keys = ./keys/jade;
    };

    janik = {
      trusted = true;
      keys = ./keys/janik;
    };

    jamie = {
      trusted = true;
      keys = ./keys/jamie;
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

    kerstin = {
      trusted = true;
      keys = ./keys/kerstin;
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

    lily = {
      trusted = true;
      keys = ./keys/lily;
    };

    lnl = {
      trusted = true;
      keys = ./keys/lnl;
    };

    lovesegfault = {
      trusted = true;
      keys = ./keys/lovesegfault;
    };

    lukegb = {
      trusted = true;
      keys = ./keys/lukegb;
    };

    m00wl = {
      trusted = true;
      keys = ./keys/m00wl;
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

    matthewcroughan = {
      name = "matthew";
      trusted = true;
      keys = ./keys/matthewcroughan;
    };

    mic92 = {
      trusted = true;
      keys = ./keys/mic92;
    };

    misuzu = {
      trusted = true;
      keys = ./keys/misuzu;
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

    noneucat = {
      trusted = true;
      keys = ./keys/noneucat;
    };

    pennae = {
      trusted = true;
      keys = ./keys/pennae;
    };

    pogobanane = {
      trusted = true;
      keys = ./keys/pogobanane;
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

    r-burns = {
      trusted = true;
      keys = ./keys/r-burns;
    };

    raitobezarius = {
      trusted = true;
      keys = ./keys/raitobezarius;
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

    solene = {
      trusted = true;
      keys = ./keys/solene;
    };

    someone = {
      trusted = true;
      keys = ./keys/someone;
    };

    sternenseemann = {
      trusted = true;
      keys = ./keys/sternenseemann;
    };

    t184256 = {
      trusted = true;
      keys = ./keys/t184256;
    };

    talyz = {
      trusted = true;
      keys = ./keys/talyz;
    };

    thecomputerguy = {
      trusted = true;
      keys = ./keys/thecomputerguy;
    };

    timokau = {
      trusted = true;
      keys = ./keys/timokau;
    };

    tomberek = {
      trusted = true;
      keys = ./keys/tomberek;
    };

    vcunat = {
      trusted = true;
      keys = ./keys/vcunat;
    };

    vikanezrimaya = {
      trusted = true;
      keys = ./keys/vikanezrimaya;
    };

    volth = {
      trusted = true;
      keys = ./keys/volth;
    };

    willibutz = {
      trusted = true;
      keys = ./keys/willibutz;
    };

    winter = {
      trusted = true;
      keys = ./keys/winter;
    };

    xeji = {
      trusted = true;
      keys = ./keys/xeji;
    };

    yegortimoshenko = {
      trusted = true;
      keys = ./keys/yegortimoshenko;
    };

    zowoq = {
      trusted = true;
      keys = ./keys/zowoq;
    };

    w4tsn = {
      trusted = true;
      keys = ./keys/w4tsn;
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
