{
  description = "Example project with less third-party dependencies";

  inputs = {
    devshell.url = "github:numtide/devshell";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nix-project.url = "github:shajra/nix-project";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      self,
      devshell,
      nixpkgs,
      ...
    }:
    let

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      overlay = import nix/overlay.nix inputs;

      buildFor =
        system:
        (import nixpkgs {
          inherit system;
          overlays = [
            overlay
            devshell.overlays.default
          ];
        });

      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f (buildFor system));

    in
    {
      packages = forAllSystems (build: rec {
        default = my-app;
        my-app = build.my-app;
      });

      apps = forAllSystems (build: rec {
        default = my-app;
        my-app = {
          type = "app";
          program = "${build.my-app}/bin/my-app";
        };
      });

      devShells = forAllSystems (build: rec {
        default = devshell;
        devshell = build.my-app-devshell;
        mkShell = build.my-app-mkShell;
      });

      formatters = forAllSystems (build: {
        default = build.my-app-treefmt.config.build.wrapper;
      });

      checks = forAllSystems (build: {
        default = build.my-app-treefmt.config.build.check self;
      });

      overlays.default = overlay;
    };
}
