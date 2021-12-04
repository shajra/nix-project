# A standard way to allow non-flake users to use this project with a standard
# default.nix file using edolstra's flake-compat project.
#
# Flake-compat has been reliably stable for some time, so you shouldn't have to
# edit this file.

let
    lock = builtins.fromJSON (builtins.readFile ../flake.lock);
    compatUrlBase = "https://github.com/edolstra/flake-compat/archive";
    url = "${compatUrlBase}/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
    flake-compat = import (fetchTarball { inherit url sha256; });

in flake-compat { src = ../.; }
