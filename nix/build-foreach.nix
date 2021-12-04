{ inputs
, nixpkgs
, ...
}:

let

    overlay = import ./overlay-build.nix inputs.orig;

    pkgs = nixpkgs.stable {
        overlays = [ overlay ];
    };

    ci = with pkgs; symlinkJoin {
        name = "nix-project-ci";
        paths = [
            nix-project-org2gfm
            nix-project-scaffold
        ];
    };

in

{
    packages.org2gfm       = pkgs.nix-project-org2gfm;
    packages.nix-scaffold  = pkgs.nix-project-scaffold;

    defaultPackage = ci;
    defaultApp = {
        type = "app";
        program = "${pkgs.nix-project-scaffold}/bin/nix-scaffold";
    };

    legacyPackages.nixpkgs = pkgs;

    lib = pkgs.nix-project-lib;
}
