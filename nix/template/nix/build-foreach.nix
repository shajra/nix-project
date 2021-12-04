{ inputs
, nixpkgs
, ...
}:

let

    overlays.deps  = import ./overlay-deps.nix inputs.system;
    overlays.build = import ./overlay-build.nix;

    pkgs = nixpkgs.stable {
        overlays = builtins.attrValues overlays;
    };

in

{
    packages.hello   = pkgs.my-hello;
    defaultPackage   = pkgs.my-hello;

    legacyPackages.nixpkgs = pkgs;

    overlays.deps = overlays.deps;
}
