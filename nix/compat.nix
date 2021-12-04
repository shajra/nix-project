let
    lock = builtins.fromJSON (builtins.readFile ../flake.lock);
    compatUrlBase = "https://github.com/edolstra/flake-compat/archive";
    url = "${compatUrlBase}/${lock.nodes.flake-compat.locked.rev}.tar.gz";
    sha256 = lock.nodes.flake-compat.locked.narHash;
    flake-compat = import (fetchTarball { inherit url sha256; });

in flake-compat { src = ../.; }
