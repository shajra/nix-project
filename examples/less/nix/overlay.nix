inputs: final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
  config = final.callPackage ../config.nix { };
in
{
  my-app = final.callPackage ./my-app.nix { };

  my-app-mkShell = prev.mkShell config.mkShell;
  my-app-devshell = final.devshell.mkShell { imports = [ config.devshell ]; };
  my-app-org2gfm = inputs.nix-project.lib.${system}.org2gfm-hermetic config.org2gfm;
  my-app-treefmt = inputs.treefmt-nix.lib.evalModule final config.treefmt;
}
