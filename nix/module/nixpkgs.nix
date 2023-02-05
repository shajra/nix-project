{ lib, ... }:

let

    isDarwin = s: builtins.any (x: x == s) lib.platforms.darwin;
    defaultInputs = (import ../../.).inputs;
    lookupOpt = { inputs', system, ... }: type:
        let name = "nixpkgs-${type}";
        in inputs'."${name}".legacyPackages
            or defaultInputs."${name}".legacyPackages."${system}";

in {
    config = {
        perSystem = args@{ config, system, inputs', ... }:
            let args' = { inherit inputs' system; };
            in {
            config._module.args.nixpkgs = lib.mkDefault {
                unstable      = lookupOpt args' "unstable";
                stable-darwin = lookupOpt args' "stable-darwin";
                stable-linux  = lookupOpt args' "stable-linux";
                stable =
                    if (isDarwin system)
                    then config._module.args.nixpkgs.stable-darwin
                    else config._module.args.nixpkgs.stable-linux;
            };
        };
    };
}
