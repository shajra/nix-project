{
    description = "A foundation to build Nix-based projects from.";

    inputs = {
        flake-compat    = { url = github:edolstra/flake-compat; flake = false; };
        flake-parts.url = github:hercules-ci/flake-parts;
        nixpkgs.url     = github:NixOS/nixpkgs/nixos-21.11;
        nix-project.url = github:shajra/nix-project;
    };

    outputs = inputs@{ flake-parts, nix-project, ... }:
        let overlay = import nix/overlay.nix inputs;
        in flake-parts.lib.mkFlake { inherit inputs; } {
            systems = [
                "x86_64-linux"
                "x86_64-darwin"
                "aarch64-darwin"
            ];
            perSystem = { pkgs, ... }:
                let build = pkgs.extend overlay;
                in {
                    packages = rec {
                        default = my-app;
                        my-app   = build.my-app;
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
                overlays.default = overlay;
            };
        };
}
