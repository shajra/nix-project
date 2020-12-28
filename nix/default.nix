let

    sources = import ./sources;

    buildOverlay = self: super: {
        niv = (import sources.niv {}).niv;
        ox-gfm = sources.ox-gfm;
        inherit nix-project-lib;
    };

    pkgs = import sources.nixpkgs-stable {
        config = {};
        overlays = [
          (import ./overlay.nix)
          buildOverlay
        ];
    };

    nix-project-lib = pkgs.recurseIntoAttrs
        (pkgs.callPackage (import ./lib.nix) {});

    nix-project-exe = pkgs.callPackage (import ./project.nix) {};

    nix-project-org2gfm = pkgs.callPackage (import ./org2gfm.nix) {};

in {
    inherit
    nix-project-exe
    nix-project-lib
    nix-project-org2gfm
    pkgs
    ;
}
