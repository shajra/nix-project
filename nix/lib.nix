{ coreutils
, lib
, runtimeShell
, shellcheck
, stdenv
, writeShellScriptBin
, writeTextFile
}:

rec {

    isDarwin = builtins.elem builtins.currentSystem lib.systems.doubles.darwin;

    writeShellChecked = name:
        { meta ? {}
        , executable ? false
        , destination ? ""
        }:
        body:
        let checkPhase = ''
                ${stdenv.shell} -n $out${destination}
                "${shellcheck}/bin/shellcheck" -x "$out${destination}"
            '';
            args = {
                inherit name executable destination checkPhase;
                text = body;
            };
        in (writeTextFile args).overrideAttrs (old: {
            meta = old.meta or {} // meta;
        });

    writeShellCheckedExe = name:
        { meta ? {}
        , exeName ? name
        }:
        body:
        writeShellChecked name {
            inherit meta;
            executable = true;
            destination = "/bin/${exeName}";
        }
        ''
            #!${runtimeShell}
            ${body}
        '';

    writeShellCheckedShareLib = name: packagePath:
        { meta ? {}
        , baseName ? name
        }:
        writeShellChecked name {
            inherit meta;
            executable = false;
            destination = "/share/${packagePath}/${baseName}.sh";
        };

    lib-sh = writeShellCheckedShareLib
        "nix-project-lib" "nix-project" {
            meta.description = "Common shell functions";
            baseName = "lib";
        }
        ''
        # shellcheck shell=bash
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
