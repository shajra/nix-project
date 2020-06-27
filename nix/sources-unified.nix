let

    srcs = import ./sources.nix;

    lib = (import srcs.nixpkgs { config = {}; }).lib;

    isDarwin = builtins.elem builtins.currentSystem lib.systems.doubles.darwin;

in

    if isDarwin
    then srcs // { nixpkgs = srcs.nixpkgs-darwin; }
    else srcs
