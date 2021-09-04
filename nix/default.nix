{ externalOverrides ? {}
}:

let

    external = import ./external // externalOverrides;

    buildOverlay = self: super: rec {
        niv = (import external.niv {}).niv;
        ox-gfm = external.ox-gfm;
        nix-project-lib = super.recurseIntoAttrs
                (self.callPackage (import ./lib.nix) {});
        nix-project-exe = self.callPackage (import ./project.nix) {};
        nix-project-org2gfm = self.callPackage (import ./org2gfm.nix) {};
    };

    nixpkgs = import external.nixpkgs-stable {
        config = {};
        overlays = [ buildOverlay ];
    };

    distribution = {
        inherit (nixpkgs)
        nix-project-lib
        nix-project-exe
        nix-project-org2gfm;
    };

in {
    inherit
    distribution
    nixpkgs;
}
