withSystem: final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
withSystem system (
  { inputs', ... }:
  {
    # Example of making an input available as a dependency
    nix-project-org2gfm = inputs'.nix-project.packages.org2gfm;

    my-app = final.callPackage ./my-app.nix { };
  }
)
