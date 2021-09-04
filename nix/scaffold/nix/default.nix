let
    sources     = import ./sources.nix;
    nixpkgs     = import sources.nixpkgs { config = {}; overlays = []; };
    nix-project = import sources.nix-project;
in {
    inherit
    nixpkgs
    nix-project;
}
