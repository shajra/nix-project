origInputs:

let

    build-forall = import ./build-forall.nix origInputs;

in

final: prev: {
    inherit (origInputs) ox-gfm;
    nix-project-lib      = final.callPackage (import ./lib origInputs) {};
    nix-project-org2gfm  = final.callPackage (import ./org2gfm.nix)    {};
    nix-project-scaffold = final.callPackage (import ./scaffold.nix)   {};
    nix-project-template = build-forall.defaultTemplate;
}
