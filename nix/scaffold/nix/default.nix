let
    sources     = import ./sources.nix;
    pkgs	= import sources.nixpkgs { config = {}; };
    nix-project = import sources.nix-project;
in
    nix-project // { inherit pkgs; }
