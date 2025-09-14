{ self, flake-parts, ... }:

{
  options.perSystem = flake-parts.lib.mkPerSystemOption (
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      cfg = config.org2gfm;
      makeScript = self.lib.${system}.org2gfm-static;
    in
    {
      _file = ./org2gfm.nix;
      options.org2gfm = {
        finalPackage = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "The wrapped org2gfm package specialized to the flake";
        };
        settings = lib.mkOption {
          type =
            with lib.types;
            submodule {
              options = {
                envCleaned = lib.mkOption {
                  type = bool;
                  default = true;
                  description = "rebuild environment variables from a clean slate";
                };
                envKeep = lib.mkOption {
                  type = listOf str;
                  default = [
                    "LANG"
                    "LOCALE_ARCHIVE"
                  ];
                  description = "variables to keep from the current environment";
                };
                pathCleaned = lib.mkOption {
                  type = bool;
                  default = true;
                  description = "rebuild PATH from a clean slate";
                };
                pathKeep = lib.mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "basenames of executables whose paths to include from current environment";
                };
                pathPackages = lib.mkOption {
                  type = listOf package;
                  default = [ ];
                  description = "packages to add to PATH";
                };
                pathExtras = lib.mkOption {
                  type = listOf str;
                  default = [
                    "/bin"
                    "/usr/bin"
                  ];
                  description = "additional paths to add to PATH";
                };
                evaluate = lib.mkOption {
                  type = bool;
                  default = true;
                  description = "evaluate all SRC blocks in Org files before exporting";
                };
                exclude = lib.mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "glob patterns for files/directories to exclude";
                };
                keepGoing = lib.mkOption {
                  type = bool;
                  default = false;
                  description = "whether to ignore failures where possible";
                };
                alwaysYes = lib.mkOption {
                  type = bool;
                  default = false;
                  description = "answer \"yes\" to all interactive prompts";
                };
                alwaysNo = lib.mkOption {
                  type = bool;
                  default = false;
                  description = "answer \"no\" to all interactive prompts";
                };
              };
            };
          default = { };
          description = "An attrset of all the flags the program takes.";
          example = ''
            {
              evaluate = true;
              exclude = [ "internal" "example" ];
              nix = "/path/to/nix";
            }
          '';
        };
      };
      config.org2gfm.finalPackage = makeScript cfg.settings;
    }
  );
}
