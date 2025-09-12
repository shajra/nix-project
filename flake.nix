{
  description = "A foundation to build Nix-based projects from.";

  inputs = {
    devshell.url = "github:numtide/devshell";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/*.tar.gz";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-stable-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-stable-linux.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    ox-gfm = {
      url = "github:syl20bnr/ox-gfm";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (flake-parts.lib) importApply;
      overlay = import nix/overlay.nix inputs;
      module-org2gfm = importApply ./nix/module/org2gfm.nix inputs;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        nix/module/lib-persystem.nix
        nix/module/nixpkgs.nix
        module-org2gfm
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem =
        { nixpkgs, config, ... }:
        let
          build = nixpkgs.stable.extend overlay;
        in
        {
          _module.args.pkgs = nixpkgs.stable;
          packages = rec {
            default = org2gfm;
            org2gfm = build.nix-project-org2gfm;
          };
          apps = rec {
            default = org2gfm;
            org2gfm = {
              type = "app";
              program = "${build.nix-project-org2gfm}/bin/org2gfm";
            };
          };
          lib = build.nix-project-lib;
          checks.build = build.nix-project-checks;
          checks.org2gfm-hermetic = config.org2gfm.finalPackage;
          legacyPackages.lib = build.nix-project-lib;
          legacyPackages.nixpkgs = nixpkgs;
          devshells.default = {
            commands = [
              {
                name = "project-update";
                help = "update project dependencies";
                command = "nix flake update --commit-lock-file";
              }
              {
                name = "project-check";
                help = "run all checks/tests/linters";
                command = "nix --print-build-logs flake check --show-trace";
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
          treefmt.pkgs = nixpkgs.unstable;
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
                nixpkgs.stable.ansifilter
                nixpkgs.stable.coreutils
                nixpkgs.stable.git
                nixpkgs.stable.gnugrep
                nixpkgs.stable.gnutar
                nixpkgs.stable.gzip
                nixpkgs.stable.jq
                nixpkgs.stable.nixfmt-rfc-style
                nixpkgs.stable.tree
              ];
              extraPaths = [
                "/bin"
              ];
              pathIncludesActiveNix = true;
              pathIncludesPrevious = false;
              exclude = [
                "internal"
                "examples"
              ];
              evaluate = true;
            };
          };
        };
      flake = {
        overlays.default = overlay;
        templates = rec {
          default = more;
          less = {
            path = ./examples/less;
            description = "Starter project with less third-party dependencies";
          };
          more = {
            path = ./examples/more;
            description = "Starter project including hercules-ci/flake-parts.";
          };
        };
        flakeModules = {
          lib-persystem = nix/module/lib-persystem.nix;
          nixpkgs = nix/module/nixpkgs.nix;
          org2gfm = module-org2gfm;
        };
      };
    };
}
