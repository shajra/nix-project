{
  description = "Example project with more third-party dependencies";

  inputs = {
    devshell.url = "github:numtide/devshell";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/*.tar.gz";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-project.url = "github:shajra/nix-project";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems-darwin.url = "github:nix-systems/aarch64-darwin";
    systems-linux.url = "github:nix-systems/x86_64-linux";
  };

  outputs =
    inputs@{
      flake-parts,
      systems-darwin,
      systems-linux,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      let
        overlay = import nix/overlay.nix withSystem;
      in
      {

        imports = [
          inputs.nix-project.flakeModules.org2gfm
          inputs.devshell.flakeModule
          inputs.treefmt-nix.flakeModule
          nix/module/my-module.nix
        ];

        systems = (import systems-darwin) ++ (import systems-linux);

        perSystem =
          { pkgs, config, ... }:
          let
            build = pkgs.extend overlay;
          in
          {
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

            my-module.enable = true;

            devshells.default = {
              commands = [
                {
                  name = "project-check";
                  help = "run all checks/tests/linters";
                  command = "nix -L flake check --show-trace";
                }
                {
                  name = "project-format";
                  help = "format all files in one command";
                  command = ''treefmt "$@"'';
                }
                {
                  name = "project-doc-gen";
                  help = "generate GitHub Markdown from Org files";
                  command = ''org2gfm-hermetic "$@"'';
                }
              ];
              packages = [
                config.treefmt.build.wrapper
                config.org2gfm.finalPackage
              ];
            };

            treefmt.programs = {
              deadnix.enable = true;
              nixfmt.enable = true;
              nixf-diagnose.enable = true;
            };

            org2gfm = {
              settings = {
                ignoreEnvironment = true;
                keepEnvVars = [
                  "LANG"
                  "LOCALE_ARCHIVE"
                ];
                pathPackages = [
                  pkgs.coreutils
                ];
                extraPaths = [
                  "/bin"
                ];
                pathIncludesPrevious = false;
                evaluate = true;
              };
            };
          };

        flake.overlays.default = overlay;
      }
    );
}
