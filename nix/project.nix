{ bash
, coreutils
, gnugrep
, gnutar
, gzip
, niv
, nix-project-lib
}:

nix-project-lib.writeShellChecked "nix-project"
''
set -eu


PROG="$(${coreutils}/bin/basename "$0")"
NIX_EXE="$(command -v nix || true)"
TOKEN=~/.config/nix-project/github.token
COMMAND=


. "${nix-project-lib.lib-sh}/bin/lib.sh"

print_usage()
{
    ${coreutils}/bin/cat - <<EOF
USAGE:

    $PROG [OPTION]... --scaffold
    $PROG [OPTION]... --upgrade
    $PROG [OPTION]... --niv -- COMMAND...

DESCRIPTION:

    A wrapper of Niv for managing Nix dependencies to assure
    dependencies Niv uses are pinned with Nix.  Also provides a
    '--scaffold' command to set up an directory as a project
    using '$PROG'.

    If multiple commands or switches are specified, the last one
    is used.

COMMANDS:

    -s, --scaffold  set up current directory with example scripts
    -u, --upgrade   upgrade dependencies with Niv
    -n, --niv       pass arguments directly to Niv

    Note '--upgrade' runs the following in one step:

        niv init; niv update

OPTIONS:

    -h, --help          print this help message
    -g, --github-token  file with GitHub API token
    -N, --nix           filepath of 'nix' executable to use

    '$PROG' pins all dependencies except for Nix itself,
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
    export PATH="${bash}/bin:$PATH"
    export PATH="${gnutar}/bin:$PATH"
    export PATH="${gzip}/bin:$PATH"
    if [ -r "$TOKEN" ]
    then
        GITHUB_TOKEN="$(${coreutils}/bin/cat "$TOKEN")"
        export GITHUB_TOKEN
    fi
}

run()
{
    if [ "$COMMAND" = niv ]
    then
        "${niv}/bin/niv" "$@"
    elif [ "$COMMAND" = upgrade ]
    then
        "${niv}/bin/niv" init
        "${niv}/bin/niv" update
    elif [ "$COMMAND" = scaffold ]
    then
        "${niv}/bin/niv" init
        build_scaffold
        "${niv}/bin/niv" update
    else
        die "no command given"
    fi
}

build_scaffold()
{
    add_nix_project
    if ! [ -e support ]
    then ${coreutils}/bin/mkdir support
    fi
    install_files ${./scaffold/support/docs-generate} \
        support/docs-generate
    install_files ${../support/dependencies-upgrade} \
        support/dependencies-upgrade
    install_files --mode 644 ${./scaffold}/nix/* nix
    install_files --mode 644 ${./scaffold}/*.org .
}

add_nix_project()
{
    if "${niv}/bin/niv" show \
        | { ! "${gnugrep}/bin/grep" \
            --quiet \
            "github.com/shajra/nix-project"; }
    then "${niv}/bin/niv" add shajra/nix-project
    fi
}

install_files()
{
    ${coreutils}/bin/install --compare --backup "$@"
}


main "$@"
''
