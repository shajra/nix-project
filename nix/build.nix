pkgs:
inputs:

let overlay = import ./overlay.nix inputs;
in pkgs.extend overlay
