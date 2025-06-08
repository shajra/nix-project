{ lib, ... }:

let

  isDarwin = s: builtins.any (x: x == s) lib.platforms.darwin;

  lookupOpt =
    { inputs', ... }:
    type:
    let
      name = "nixpkgs-${type}";
    in
    inputs'."${name}".legacyPackages or inputs'.nix-project.legacyPackages.nixpkgs."${type}";

in
{
  config = {
    perSystem =
      {
        config,
        system,
        inputs',
        ...
      }:
      let
        args = { inherit inputs' system; };
      in
      {
        config._module.args.nixpkgs = lib.mkDefault {
          master = lookupOpt args "master";
          unstable = lookupOpt args "unstable";
          stable-darwin = lookupOpt args "stable-darwin";
          stable-linux = lookupOpt args "stable-linux";
          stable =
            if (isDarwin system) then
              config._module.args.nixpkgs.stable-darwin
            else
              config._module.args.nixpkgs.stable-linux;
        };
      };
  };
}
