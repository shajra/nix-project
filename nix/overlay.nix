self: super: {
    ansifilter = super.ansifilter.overrideAttrs (old: {
        postPatch = ''
            substituteInPlace src/makefile --replace CC=g++ CC=c++
        '';
        meta = old.meta // {
            platforms = old.meta.platforms ++ super.lib.platforms.darwin;
        };
    });
}
