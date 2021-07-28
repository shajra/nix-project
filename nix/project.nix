{ bash
, coreutils
, gnugrep
, gnused
, gnutar
, gzip
, niv
, nix-project-lib
}:

let
    progName = "nix-project";
    meta.description =
        "Script to scaffold and maintain dependencies for a Nix project";
in

nix-project-lib.writeShellCheckedExe progName
{
    inherit meta;
    pathPure = false;
    path = [
        coreutils
        gnused
        gnutar
        gzip
        niv
    ];
}
''
set -eu
set -o pipefail


NIX_EXE="$(command -v nix || true)"
TARGET_DIR="$(pwd)"
NIV_DIR="nix"
TOKEN=~/.config/nix-project/github.token
COMMAND=


. "${nix-project-lib.lib-sh}/share/nix-project/lib.sh"

print_usage()
{
    cat - <<EOF
USAGE:

    ${progName} [OPTION]... --scaffold
    ${progName} [OPTION]... --upgrade
    ${progName} [OPTION]... --niv -- COMMAND...

DESCRIPTION:

    A wrapper of Niv for managing Nix dependencies to assure
    dependencies Niv uses are pinned with Nix.  Also provides a
    '--scaffold' command to set up an directory as a project
    using '${progName}'.

    If multiple commands are specified, the last one is used.
    Similarly, if a switch is specified multiple times, the last
    one is used.

COMMANDS:

    -s --scaffold  set up current directory with example scripts
    -u --upgrade   upgrade dependencies with Niv
    -n --niv       pass arguments directly to Niv

    Note '--upgrade' runs the following in one step:

        niv init; niv update

OPTIONS:

    -h --help            print this help message
    -t --target-dir DIR  directory of project to manage
                          (default: current directory)
    -S --source-dir DIR  directory relative to target for
                          Nix files (default: nix)
    -g --github-token    file with GitHub API token (default:
                          ~/.config/nix-project/github.token)
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
        -u|--upgrade)
            COMMAND=upgrade
            ;;
        -s|--scaffold)
            COMMAND=scaffold
            ;;
        -n|--niv)
            COMMAND=niv
            ;;
        -t|--target-dir)
            TARGET_DIR="''${2:-}"
            if [ -z "$TARGET_DIR" ]
            then die "$1 requires argument"
            fi
            shift
            ;;
        -S|--source-dir)
            NIV_DIR="''${2:-}"
            if [ -z "$NIV_DIR" ]
            then die "$1 requires argument"
            fi
            shift
            ;;
        -N|--nix)
            NIX_EXE="''${2:-}"
            if [ -z "$NIX_EXE" ]
            then die "$1 requires argument"
            fi
            shift
            ;;
        -g|--github-token)
            TOKEN="''${2:-}"
            if [ -z "$TOKEN" ]
            then die "$1 requires argument"
            fi
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
        esac
        shift
    done
    setup_env "$NIX_EXE"
    run "$@"
}

setup_env()
{
    add_nix_to_path "$1"
    if [ -r "$TOKEN" ]
    then
        GITHUB_TOKEN="$(cat "$TOKEN")"
        export GITHUB_TOKEN
    fi
}

run()
{
    if [ "$COMMAND" = niv ]
    then
        run_niv "$@"
    elif [ "$COMMAND" = upgrade ]
    then
        niv_init
        run_niv update
    elif [ "$COMMAND" = scaffold ]
    then
        niv_init
        add_nix_project
        install_scripts
        run_niv update
    else
        die "no command given"
    fi
}

install_scripts()
{
    local support_dir; support_dir="$(target_dir)/support"
    if ! [ -e "$support_dir" ]
    then mkdir "$support_dir"
    fi
    install_files ${./scaffold/support/docs-generate} \
        "$support_dir/docs-generate"
    install_files ${./scaffold/support/dependencies-upgrade} \
        "$support_dir/dependencies-upgrade"
    sed -i -e "s|@NIV_DIR@|$NIV_DIR|" "$support_dir"/*
    install_files --mode 644 ${./scaffold}/nix/* "$(niv_dir)"
    install_files --mode 644 ${./scaffold}/*.org "$(target_dir)"
}

add_nix_project()
{
    if ! run_niv show nix-project > /dev/null 2>&1
    then run_niv add shajra/nix-project
    fi
}

install_files()
{
    install --compare --backup "$@"
}

niv_init()
{
    local dest; dest="$(niv_dir)"
    local tmp; tmp="$(mktemp -d)"
    trap 'rm -rf "'"$tmp"'"' EXIT
    (
        cd "$tmp"
        niv init
    ) > /dev/null
    mkdir -p "$dest"
    cp "$tmp/nix/sources.nix" "$dest"
    if ! [ -e "$dest/sources.json" ]
    then cp "$tmp/nix/sources.json" "$dest"
    fi
}

run_niv()
{
    niv --sources-file "$(niv_dir)/sources.json" "$@"
}

target_dir()
{
    readlink --canonicalize "$TARGET_DIR"
}

niv_dir()
{
    echo "$(target_dir)/$NIV_DIR"
}


main "$@"
''
