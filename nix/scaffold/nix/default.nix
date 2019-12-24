let
    sources     = import ./sources.nix;
    pkgs	= import sources.nixpkgs {};
    nix-project = import sources.nix-project;
in
    nix-project // { inherit pkgs; }
