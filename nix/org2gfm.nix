{ coreutils
, emacsWithPackages
, findutils
, ox-gfm
, writeText
, nix-project-common
}:

let

    emacs = emacsWithPackages (epkgs: [
        epkgs.melpaStablePackages.dash
        epkgs.melpaStablePackages.ox-gfm
    ]);

    init = writeText "init.el" ''
        (add-to-list 'load-path "${ox-gfm}")
        (require 'dash)
        (require 'ob-shell)
        (require 'ox)
        (require 'ox-gfm)
        (setq-default
         org-confirm-babel-evaluate nil
         make-backup-files nil
         org-html-inline-image-rules
          '(("file"  . "\\.\\(jpeg\\|jpg\\|png\\|gif\\|svg\\)\\'")
            ("http"  . "\\.\\(jpeg\\|jpg\\|png\\|gif\\|svg\\)\\(\\?.*\\)?\\'")
            ("https" . "\\.\\(jpeg\\|jpg\\|png\\|gif\\|svg\\)\\(\\?.*\\)?\\'")))
    '';

in

nix-project-common.writeShellChecked "org2gfm"
''
set -eu


EVALUATE=false
NIX_EXE=


. "${nix-project-common.lib-sh}/bin/lib.sh"

print_usage()
{
    ${coreutils}/bin/cat - <<EOF
USAGE: $(${coreutils}/bin/basename "$0") [OPTION]...  [FILE]...

DESCRIPTION:

    Uses Emacs to convert Org-mode files to GitHub Flavored
    Markdown, which are written to sibling ".md" files.  If no
    files are specified, then all '*.org' files found recursively
    from the current working directory are used instead.

OPTIONS:

    -h, --help         print this help message
    -e, --evaluate     evaluate all SRC blocks
    -E, --no-evaluate  don't evaluate any SRC blocks (default)
    -n, --nix NIX_EXE  filepath to 'nix' binary to put on PATH
    -N, --no-nix       don't put found Nix binaries on PATH
                       (default)

    This script is recommended for use in a clean environment
    with a PATH controlled by Nix.  This helps make executed
    source blocks more deterministic.  However, if the source
    blocks need to execute Nix commands, it's best to use the Nix
    version already installed on the system, rather than a pinned
    version.  This is what the '-n' option is for.

    If using both '-e' and '-E' options (or similarly '-n' and
    '-N'), the last one is overriding (useful for
    automation/defaults).

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
        -e|--evaluate)
            EVALUATE="true"
            ;;
        -E|--no-evaluate)
            EVALUATE="false"
            ;;
        -n|--nix)
            NIX_EXE="''${2:-}"
            if [ -z "$NIX_EXE" ]
            then die "$1 requires argument"
            fi
            shift
            ;;
        -N|--no-nix)
            NIX_EXE=
            ;;
        *)
            break
            ;;
        esac
        shift
    done

    add_nix_to_path "$NIX_EXE"
    if [ "$#" -gt 0 ]
    then generate_gfm_args "$@"
    else generate_gfm_found
    fi
}

generate_gfm_args()
{
    for f in "$@"
    do generate_gfm "$f"
    done
}

generate_gfm_found()
{
    ${findutils}/bin/find . \
        -name '*.org' | \
    {
        while read -r f
        do generate_gfm "$f"
        done
    }
}

generate_gfm()
{
    local filepath="$1"
    if [ "$EVALUATE" = true ]
    then
        ${emacs}/bin/emacs \
            --batch \
            --kill \
            --load ${init} \
            --file "$filepath" \
            --eval "(princ buffer-file-name 'external-debugging-output)" \
            --eval "(princ \"\\n\" 'external-debugging-output)" \
            --eval "(org-babel-execute-buffer)" \
            --funcall save-buffer \
            --funcall org-gfm-export-to-markdown
    else
        ${emacs}/bin/emacs \
            --batch \
            --kill \
            --load ${init} \
            --file "$filepath" \
            --eval "(princ buffer-file-name 'external-debugging-output)" \
            --eval "(princ \"\\n\" 'external-debugging-output)" \
            --funcall org-gfm-export-to-markdown
    fi
}


main "$@"
''
