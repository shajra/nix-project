let
    sources     = import ./sources.nix;
    pkgs        = import sources.nixpkgs { config = {}; overlays = []; };
in
    pkgs // (import sources.nix-project)
