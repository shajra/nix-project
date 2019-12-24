let

    sources = import ./sources.nix;

    pkgs    = import sources.nixpkgs { config = {}; };
    lib  = pkgs.callPackage (import ./lib.nix) {};
    org2gfm = pkgs.callPackage (import ./org2gfm.nix) {
        ox-gfm = sources.ox-gfm;
        nix-project-lib = lib;
    };
    nix-project = pkgs.callPackage (import ./project.nix) {
        niv = (import sources.niv {}).niv;
        nix-project-lib = lib;
    };
in { inherit lib org2gfm nix-project pkgs; }
