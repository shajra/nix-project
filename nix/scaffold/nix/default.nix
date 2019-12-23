let
    sources     = import ./sources.nix;
    pkgs	= import sources.nixpkgs {};
    org2gfm     = (import sources.nix-project).org2gfm;
    nix-project = (import sources.nix-project).nix-project;
in 
    { inherit org2gfm nix-project pkgs; }
