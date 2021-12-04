origInputs:
lib:

let data   = import ./data.nix   lib;
    flakes = import ./flakes.nix origInputs lib data;
in { inherit data flakes; }
