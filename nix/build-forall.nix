origInputs:

let

    overlay = import ./overlay-build.nix origInputs;
    lib = import lib/forall origInputs origInputs.nixpkgs-stable-linux.lib;

    template = {
        path = ./template;
        description = "A starter project using shajra/nix-project.";
    };

in

{
    inherit overlay lib;
    defaultTemplate = template;
}
