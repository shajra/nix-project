{ coreutils
, emacsWithPackages
, findutils
, gnugrep
, ox-gfm
, writeText
, nix-project-lib
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

nix-project-lib.writeShellChecked "org2gfm"
''
set -eu


EVALUATE=false
IGNORE_REGEX=
NIX_EXE=


. "${nix-project-lib.lib-sh}/bin/lib.sh"

print_usage()
{
    ${coreutils}/bin/cat - <<EOF
USAGE: $(${coreutils}/bin/basename "$0") [OPTION]...  [FILE]...

DESCRIPTION:

    Uses Emacs to export Org-mode files to GitHub Flavored
    Markdown, which are written to sibling ".md" files.  If no
    files are specified, then all '*.org' files found recursively
    from the current working directory are used instead.

OPTIONS:

    -h, --help          print this help message
    -e, --evaluate      evaluate all SRC blocks before exporting
    -E, --no-evaluate   don't evaluate before exporting (default)
    -n, --nix NIX_EXE   filepath to 'nix' binary to put on PATH
    -N, --no-nix        don't put found Nix binaries on PATH
                        (default)
    -i, --ignore REGEX  ignore matched paths when searching

    This script is recommended for use in a clean environment
    with a PATH controlled by Nix.  This helps make executed
    source blocks more deterministic.  However, if the source
    blocks need to execute Nix commands, it's best to use the Nix
    version already installed on the system, rather than a pinned
    version.  This is what the '-n' option is for.

    If using both '-e' and '-E' options (or similarly '-n' and
    '-N'), the last one is overriding (useful for
    automation/defaults).

    Note, the '-e' switch evaluates the Org-mode file in-place.
    No evaluation occurs during the export to Markdown, which
    will have the same blocks as the Org-mode file.


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
        -i|--ignore)
            IGNORE_REGEX="''${2:-}"
            if [ -z "$IGNORE_REGEX" ]
            then die "$1 requires argument"
            fi
            shift
            ;;
        *)
            break
            ;;
        esac
        shift
    done

    if [ -n "$NIX_EXE" ]
    then add_nix_to_path "$NIX_EXE"
    fi
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
    ${findutils}/bin/find .  -name '*.org' \
    | ignore_regex \
    | {
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
            --eval "(setq-default org-export-use-babel nil)" \
            --funcall org-babel-execute-buffer \
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
            --eval "(setq-default org-export-use-babel nil)" \
            --funcall org-gfm-export-to-markdown
    fi
}

ignore_regex()
{
    if [ -n "$IGNORE_REGEX" ]
    then ${gnugrep}/bin/grep -v "$IGNORE_REGEX"
    else cat -
    fi
}


main "$@"
''
