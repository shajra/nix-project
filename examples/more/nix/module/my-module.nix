{
  config,
  flake-parts-lib,
  lib,
  ...
}:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      moduleApp = pkgs.writeShellApplication {
        name = "my-module-app";
        meta.description = "Example application provided by example module";
        text = ''
          echo "${config.my-module.message}"
        '';
      };
    in
    {
      _file = ./my-module.nix;
      options.my-module = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable the my-module module";
        };

        message = lib.mkOption {
          type = lib.types.str;
          default = "Greetings, World!";
          description = "Greeting to display";
        };
      };

      config = lib.mkIf config.my-module.enable {
        packages.my-module-app = moduleApp;
        apps.my-module-app = {
          type = "app";
          program = "${moduleApp}/bin/my-module-app";
        };
      };
    }
  );

  config.flake.flakeModules.my-module = lib.mkIf (builtins.any (c: c.my-module.enable or false) (
    builtins.attrValues config.allSystems
  )) (import ./my-module.nix);
}
