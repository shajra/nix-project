origInputs:

{ callPackage
, lib
}:

let

    forall  = import ./forall  origInputs lib;
    foreach = import ./foreach callPackage;

in lib.recursiveUpdate foreach forall
