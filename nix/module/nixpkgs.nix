{ lib, ... }:

let

    isDarwin = s: builtins.any (x: x == s) lib.platforms.darwin;
    rejectFile = path: type: regex:
        type != "regular" || builtins.match regex path == null;
    rejectDir = path: type: regex:
        type != "directory" || builtins.match regex path == null;
    nix-project = builtins.path {
        path = ../../.;
        name = "nix-project";
        filter = path: type:
            (rejectFile path type ".*[.](md|org)")
            && (rejectDir path type "[.]git")
            && (rejectDir path type "[.]github")
            && (rejectFile path type "result.*");
    };
    defaultInputs = (builtins.getFlake (toString nix-project)).inputs;

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
                master        = lookupOpt args' "master";
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
