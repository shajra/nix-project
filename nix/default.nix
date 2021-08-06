{ externalOverrides ? {}
}:

let

    external = import ./external // externalOverrides;

    buildOverlay = self: super: {
        niv = (import external.niv {}).niv;
        ox-gfm = external.ox-gfm;
        inherit nix-project-lib;
    };

    pkgs = import external.nixpkgs-stable {
        config = {};
        overlays = [ buildOverlay ];
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
