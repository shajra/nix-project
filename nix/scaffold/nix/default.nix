let
    sources     = import ./sources.nix;
    pkgs        = import sources.nixpkgs { config = {}; overlays = []; };
    nix-project = import sources.nix-project;
in
    pkgs // nix-project
