{ pkgs }:

{
  devshell = {
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
      pkgs.my-app-org2gfm
      pkgs.my-app-treefmt.config.build.wrapper
    ];
    packagesFrom = [ pkgs.my-app ];
  };

  mkShell = {
    packages = [
      pkgs.my-app-org2gfm
      pkgs.my-app-treefmt.config.build.wrapper
    ];
    inputsFrom = [ pkgs.my-app ];
  };

  treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      deadnix.enable = true;
      nixfmt.enable = true;
      nixf-diagnose.enable = true;
    };
  };

  org2gfm = {
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
}
