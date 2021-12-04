{ flake-utils
, nixpkgs-stable-darwin
, nixpkgs-stable-linux
, nixpkgs-unstable
, ...
}:

lib:
data:

let

    isDarwin = s: (builtins.match ".*-darwin" s) == [];

    eachSystem = flake-utils.lib.eachSystem;

    load = path:
        if path == null
        then _: {}
        else if builtins.typeOf path == "lambda"
        then path
        else import path;

    forSystems = origInputs: systems: f: eachSystem systems (system:
        let
            nixpkgs-stable =
                if (isDarwin system)
                then nixpkgs-stable-darwin
                else nixpkgs-stable-linux;
            makeNixpkgs = np: args: import np (args // { inherit system; });
            nixpkgs.stable-darwin = makeNixpkgs nixpkgs-stable-darwin;
            nixpkgs.stable-linux = makeNixpkgs nixpkgs-stable-linux;
            nixpkgs.stable = makeNixpkgs nixpkgs-stable;
            nixpkgs.unstable = makeNixpkgs nixpkgs-unstable;
            inputs.orig = origInputs;
            inputs.system =
                let notSelectable = set: !(set ? "${system}");
                    select = path: v: v."${system}" or v;
                in lib.mapAttrsRecursiveCond notSelectable select origInputs;
        in load f { inherit inputs nixpkgs system; }
    );

    buildFlake =
        { inputs
        , systems ? []
        , forAllSystems ? null
        , forEachSystem ? null
        }:
        let all = load forAllSystems inputs;
            each = forSystems inputs systems forEachSystem;
            eachAndAll = lib.recursiveUpdate each all;
            fixedOverlays = data.flatten "-" (eachAndAll.overlays or {});
        in eachAndAll // { overlays = fixedOverlays; };

in flake-utils.lib // { inherit forSystems buildFlake; }

