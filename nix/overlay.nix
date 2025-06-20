inputs: final: prev: {
  inherit (inputs) ox-gfm;
  nix-project-lib.scripts = final.callPackage (import ./scripts.nix) { };
  nix-project-lib.org2gfm-hermetic = final.callPackage (import ./org2gfm-hermetic.nix) { };
  nix-project-org2gfm = final.callPackage (import ./org2gfm.nix) { };
  nix-project-checks = prev.linkFarm "nix-project-ci" {
    inherit (final) nix-project-org2gfm;
  };
}
