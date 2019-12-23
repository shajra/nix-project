{ coreutils
, shellcheck
, writeShellScriptBin
}:

rec {

    writeScript = name: body:
        (writeShellScriptBin name body).overrideAttrs (old: {
            buildCommand = ''
                ${old.buildCommand}
                ${shellcheck}/bin/shellcheck -x $out/bin/${name}
            '';
        });

    lib-sh = writeScript "lib.sh" ''
        add_nix_to_path()
        {
            local nix_exe="$1"
            if [ -x "$nix_exe" ] \
                && [ "$(${coreutils}/bin/basename "$nix_exe")" = "nix" ]
            then PATH="$(path_for "$nix_exe"):$PATH"
            else die "invalid filepath of 'nix' executable: $nix_exe"
            fi
            export PATH
        }
        
        path_for()
        {
            "${coreutils}"/bin/dirname \
                "$("${coreutils}"/bin/readlink --canonicalize "$1")"
        }
        
        die()
        {
            print_usage >&2
            echo
            echo "ERROR: $1" >&2
            exit 1
        }
    '';

}
