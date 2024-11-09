{
    description = "A foundation to build Nix-based projects from.";

    inputs = {
        flake-compat    = { url = "github:edolstra/flake-compat"; flake = false; };
        flake-parts.url = "github:hercules-ci/flake-parts";
        nixpkgs.url     = "github:NixOS/nixpkgs/nixos-21.11";
        nix-project.url = "github:shajra/nix-project";
    };

    outputs = inputs@{ flake-parts, nix-project, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } ({withSystem, config, ... }: {
            systems = [
                "x86_64-linux"
                "x86_64-darwin"
                "aarch64-darwin"
            ];
            perSystem = { pkgs, ... }:
                let build = pkgs.extend config.flake.overlays.default;
                in {
                    packages = rec {
                        default = my-app;
                        inherit (build) my-app;
                    };
                    legacyPackages.nixpkgs = build;
                    apps = rec {
                        default = my-app;
                        my-app = {
                            type = "app";
                            program = "${build.my-app}/bin/my-app";
                        };
                    };
                };
            flake = {
                overlays.default = import nix/overlay.nix withSystem;
            };
        });
}
