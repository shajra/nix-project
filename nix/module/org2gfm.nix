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
                envImpure = lib.mkOption {
                  type = bool;
                  default = false;
                  description = "rebuild environment from a clean slate";
                };
                envKeep = lib.mkOption {
                  type = listOf str;
                  default = [
                    "LANG"
                    "LOCALE_ARCHIVE"
                  ];
                  description = "variables to keep when ignoring environment";
                };
                pathPackages = lib.mkOption {
                  type = listOf package;
                  default = [ ];
                  description = "packages to explicitly put on PATH (even when ignoring environment)";
                };
                pathExtras = lib.mkOption {
                  type = listOf str;
                  default = [
                    "/bin"
                    "/usr/bin"
                  ];
                  description = "include paths like /bin (even when ignoring environment)";
                };
                pathImpureSelected = lib.mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "include path to selected executable names on PATH (even when ignoring environment)";
                };
                pathImpureAll = lib.mkOption {
                  type = bool;
                  default = false;
                  description = "include previous PATH (even when ignoring environment)";
                };
                evaluate = lib.mkOption {
                  type = bool;
                  default = true;
                  description = "evaluate all SRC blocks before exporting";
                };
                exclude = lib.mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "exclude matched when searching";
                };
                keepGoing = lib.mkOption {
                  type = bool;
                  default = false;
                  description = "don't stop if Babel executes non-zero";
                };
                alwaysYes = lib.mkOption {
                  type = bool;
                  default = false;
                  description = "answer \"yes\" to all queries for evaluation";
                };
                alwaysNo = lib.mkOption {
                  type = bool;
                  default = false;
                  description = "answer \"no\" to all queries for evaluation";
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
