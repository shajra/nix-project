let
    sources = import ./sources.nix;
    pkgs    = import sources.nixpkgs { config = {}; };
    common  = pkgs.callPackage (import ./common.nix) {};
    org2gfm = pkgs.callPackage (import ./org2gfm.nix) {
        ox-gfm = sources.ox-gfm;
        nix-project-common = common;
    };
    nix-project = pkgs.callPackage (import ./project.nix) {
        niv = (import sources.niv {}).niv;
        nix-project-common = common;
    };
in { inherit common org2gfm nix-project pkgs; }
