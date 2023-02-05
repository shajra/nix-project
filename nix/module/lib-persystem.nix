{ lib, flake-parts-lib, ... }:

flake-parts-lib.mkTransposedPerSystemModule {
    name = "lib";
    option = lib.mkOption {
        type = lib.types.anything;
        default = { };
        description = ''
            An attribute set of system-specific library functions.
        '';
    };
    file = ./lib-persystem.nix;
}
