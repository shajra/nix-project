lib:

# TODO: This code is copied from https://github.com/grahamc/nix-shenanigans.  I
# sort of have permission [1].  If I rewrote it as an exericse, I wonder how
# similar my solution would be.
#
# [1]: https://twitter.com/shajra/status/1485735521695506432.

let

    flatten = sep: val: lib.listToAttrs
        (map
            (elem:
                let name = builtins.concatStringsSep sep elem.path;
                in elem // { inherit name; }
            )
            (
                if lib.isList val then (flattenListToAttrList [] val)
                else if lib.isAttrs val then (flattenSetToAttrList [] val)
                else throw "flattenSet can't handle this? ${val}"
            )
        );

    flattenListToAttrList = path: xs:
        builtins.concatLists
            (lib.imap
                (i: v:
                    let ident = path ++ ["${toString (i - 1)}"];
                    in flatten' ident v)
                xs);

    flattenSetToAttrList = path: attrset:
        let keys = builtins.attrNames attrset;
        in builtins.concatLists (
            map (key:
                let ident = path ++ [key];
                    curValue = (builtins.getAttr key attrset);
                in flatten' ident curValue
            ) keys
        );

    flatten' = path: val:
        if lib.isDerivation val then (pathValueElem path val)
        else if lib.isBool val then (pathValueElem path val)
        else if lib.isInt val then (pathValueElem path val)
        else if lib.isString val then (pathValueElem path val)
        else if lib.isFunction val then (pathValueElem path val)
        else if lib.isList val then (flattenListToAttrList path val)
        else if lib.isAttrs val then (flattenSetToAttrList path val)
        else throw "flatten' can't handle this? ${val}";

    pathValueElem = path: value: [{ path = path; value = value; }];

in { inherit flatten; }
