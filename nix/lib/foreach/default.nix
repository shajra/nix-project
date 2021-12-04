callPackage:

let scripts = callPackage ./scripts.nix {};
in { inherit scripts; }
