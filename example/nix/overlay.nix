inputs:

let get = pkgs: input: name:
        let system = pkgs.stdenv.hostPlatform.system;
        in inputs.${input}.packages.${system}.${name};

in final: prev: {
    nix-project-org2gfm = get final "nix-project" "org2gfm";
    my-app = final.callPackage ./my-app.nix {};
}
