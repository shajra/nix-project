{
    description = "A foundation to build Nix-based projects from.";

    inputs = {
        flake-compat.url          = "https://flakehub.com/f/edolstra/flake-compat/*.tar.gz";
        flake-parts.url           = "github:hercules-ci/flake-parts";
        nixpkgs-master.url        = "github:NixOS/nixpkgs/master";
        nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
        nixpkgs-stable-linux.url  = "github:NixOS/nixpkgs/nixos-25.05";
        nixpkgs-unstable.url      = "github:NixOS/nixpkgs/nixpkgs-unstable";
        ox-gfm            = { url = "github:syl20bnr/ox-gfm"; flake = false; };
    };

    outputs = inputs@{ flake-parts, ... }:
        let overlay = import nix/overlay.nix inputs;
        in flake-parts.lib.mkFlake { inherit inputs; } {
            imports = [
                nix/module/lib-persystem.nix
                nix/module/nixpkgs.nix
            ];
            systems = [
                "x86_64-linux"
                "x86_64-darwin"
                "aarch64-darwin"
            ];
            perSystem = { nixpkgs, ... }:
                let build = nixpkgs.stable.extend overlay;
                in {
                    packages = rec {
                        org2gfm      = build.nix-project-org2gfm;
                        nix-scaffold = build.nix-project-scaffold;
                    };
                    checks.ci              = build.nix-project-ci;
                    legacyPackages.lib     = build.nix-project-lib;
                    legacyPackages.nixpkgs = nixpkgs;
                    apps = rec {
                        default = nix-scaffold;
                        nix-scaffold = {
                            type = "app";
                            program = "${build.nix-project-scaffold}/bin/nix-scaffold";
                        };
                    };
                    lib = build.nix-project-lib;
                };
            flake = {
                overlays.default = overlay;
                templates.default = {
                    path = ./example;
                    description = "A starter project using shajra/nix-project.";
                };
                flakeModules = {
                    lib-persystem = nix/module/lib-persystem.nix;
                    nixpkgs = nix/module/nixpkgs.nix;
                };
            };
        };
}
