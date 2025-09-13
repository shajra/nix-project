inputs: final: prev:
let
  org2gfm = final.callPackage ./org2gfm.nix { };
in
{
  inherit (inputs) ox-gfm;
  nix-project-lib.scripts = final.callPackage ./scripts.nix { };
  nix-project-lib.org2gfm = org2gfm.org2gfm;
  nix-project-lib.org2gfm-static = final.callPackage ./org2gfm-static.nix { };
  nix-project-org2gfm-impure = org2gfm.org2gfm-impure;
  nix-project-checks = prev.linkFarm "nix-project-checks" {
    inherit (final) nix-project-org2gfm-impure;
  };
}
