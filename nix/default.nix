let

    sources = import ./sources.nix;

    pkgs    = import sources.nixpkgs { config = {}; };

    nix-project-lib = pkgs.callPackage (import ./lib.nix) {};

    nix-project-exe = pkgs.callPackage (import ./project.nix) {
        niv = (import sources.niv {}).niv;
        inherit nix-project-lib;
    };

    nix-project-org2gfm = pkgs.callPackage (import ./org2gfm.nix) {
        ox-gfm = sources.ox-gfm;
        inherit nix-project-lib;
    };

in {
    inherit
    nix-project-exe
    nix-project-lib
    nix-project-org2gfm
    pkgs;
}
