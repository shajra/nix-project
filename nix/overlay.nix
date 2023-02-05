inputs:
final: prev: {
    inherit (inputs) ox-gfm;
    nix-project-lib.scripts = final.callPackage (import ./scripts.nix)  {};
    nix-project-org2gfm     = final.callPackage (import ./org2gfm.nix)  {};
    nix-project-scaffold    = final.callPackage (import ./scaffold.nix) {};
    nix-project-ci = prev.symlinkJoin {
        name = "nix-project-ci";
        paths = [
            final.nix-project-org2gfm
            final.nix-project-scaffold
        ];
    };
}
