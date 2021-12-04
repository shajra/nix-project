{
    description = "A foundation to build Nix-based projects from.";

    inputs = {
        flake-compat      = { url = "github:edolstra/flake-compat"; flake = false; };
        flake-utils.url           = "github:numtide/flake-utils";
        nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin";
        nixpkgs-stable-linux.url  = "github:NixOS/nixpkgs/nixos-21.11";
        nixpkgs-unstable.url      = "github:NixOS/nixpkgs/nixpkgs-unstable";
        ox-gfm            = { url = "github:syl20bnr/ox-gfm"; flake = false; };
    };

    outputs = inputs:
        let build = import nix/build-forall.nix inputs;
            systems = [
                "x86_64-linux"
                "x86_64-darwin"
                "aarch64-darwin"
            ];
        in build.lib.flakes.buildFlake {
            inherit inputs systems;
            forAllSystems = nix/build-forall.nix;
            forEachSystem = nix/build-foreach.nix;
        };
}
