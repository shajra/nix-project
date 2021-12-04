{
    description = "A foundation to build Nix-based projects from.";

    inputs = {
        nix-project.url = "github:shajra/nix-project/user/shajra/next";
    };

    outputs = inputs:
        let lib-flakes = import nix/build-forall.nix inputs;
            systems = [
                "x86_64-linux"
                "x86_64-darwin"
                "aarch64-darwin"
            ];
        in inputs.nix-project.lib.flakes.buildFlake {
            inherit inputs systems;
            forAllSystems = nix/build-forall.nix;
            forEachSystem = nix/build-foreach.nix;
        };
}
