{ bash
, coreutils
, gnugrep
, gnused
, gnutar
, gzip
, lib
, nix-project-lib
}:

let
    progName = "nix-scaffold";
    meta.description =
        "Script to scaffold a Nix project";
    source = lib.cleanSourceWith {
        src = lib.sourceFilesBySuffices ../. [
            "docs-generate"
            ".lock"
            ".nix"
            ".org"
        ];
        filter = path: type:
            let baseName = builtins.baseNameOf path;
            in (type == "directory")
                || (builtins.match ".*/template/.*" path != null)
                || (type == "regular" && ! lib.hasSuffix ".org" baseName);
    };
in

nix-project-lib.scripts.writeShellCheckedExe progName
{
    inherit meta;
    pathPure = false;
    path = [
        coreutils
        gnused
        gnutar
        gzip
    ];
}
''
set -eu
set -o pipefail


NIX_EXE="$(command -v nix || true)"
TARGET_DIR="$(pwd)"


. "${nix-project-lib.scripts.scriptCommon}/share/nix-project/common.bash"

print_usage()
{
    cat - <<EOF
USAGE: ${progName} [OPTION]...

DESCRIPTION:

    Scaffolds a new project based on Nix flakes.

OPTIONS:

    -h --help            print this help message
    -t --target-dir DIR  directory of project to manage
                          (default: current directory)
    -N --nix PATH        filepath of 'nix' executable to use

    '${progName}' pins all dependencies except for Nix itself,
     which it finds on the path if possible.  Otherwise set
     '--nix'.

EOF
}

main()
{
    while ! [ "''${1:-}" = "" ]
    do
        case "$1" in
        -h|--help)
            print_usage
            exit 0
            ;;
        -t|--target-dir)
            if [ -z "''${2:-}" ]
            then die "$1 requires argument"
            fi
            TARGET_DIR="''${2:-}"
            shift
            ;;
        -N|--nix)
            if [ -z "''${2:-}" ]
            then die "$1 requires argument"
            fi
            NIX_EXE="''${2:-}"
            shift
            ;;
        *)
            die "unrecognized argument: $1"
            ;;
        esac
        shift
    done
    add_nix_to_path "$NIX_EXE"
    run "$@"
}

run()
{
    local target; target="$(target_dir)"
    nix flake new -t "${source}" "$target"
    chmod +x "$target"/support/*
    echo "SUCCESS: Scaffolded Nix project at $target"
}

target_dir()
{
    readlink --canonicalize "$TARGET_DIR"
}


main "$@"
''
