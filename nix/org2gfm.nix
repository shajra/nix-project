{
  coreutils,
  emacs,
  fd,
  git,
  gnugrep,
  ox-gfm,
  writeText,
  nix-project-lib,
}:

let

  progName = "org2gfm";
  meta.description = "Exports Org-mode files to GitHub Flavored Markdown (GFM)";

  emacsWithPkgs = emacs.pkgs.withPackages (epkgs: [
    epkgs.melpaStablePackages.dash
    epkgs.melpaStablePackages.f
    epkgs.melpaStablePackages.ox-gfm
  ]);

  init = writeText "init.el" ''
    (add-to-list 'load-path "${ox-gfm}")
    (require 'dash)
    (require 'f)
    (require 'ob-shell)
    (require 'ox)
    (require 'ox-gfm)
    (require 'subr-x)
    (setq-default
     vc-git-program "${git}/bin/git"
     org-confirm-babel-evaluate nil
     org-babel-default-header-args
      (cons '(:eval . "no-export")
            (default-value 'org-babel-default-header-args))
     make-backup-files nil
     org-html-inline-image-rules
      '(("file"  . "\\.\\(jpeg\\|jpg\\|png\\|gif\\|svg\\)\\'")
        ("http"  . "\\.\\(jpeg\\|jpg\\|png\\|gif\\|svg\\)\\(\\?.*\\)?\\'")
        ("https" . "\\.\\(jpeg\\|jpg\\|png\\|gif\\|svg\\)\\(\\?.*\\)?\\'")))
    (defun org2gfm-log (action)
      (princ (concat "\n" action ": " buffer-file-name "\n")
             'external-debugging-output))
  '';

  org2gfm =
    {
      pathImpureAll ? false,
      pathImpureSelected ? [ ],
      pathPackages ? [ ],
      pathExtras ? [ ],
      envImpure ? false,
      envKeep ? [
        "LANG"
        "LOCALE_ARCHIVE"
      ],
    }:
    nix-project-lib.scripts.writeShellCheckedExe progName
      {
        inherit
          meta
          pathImpureAll
          pathImpureSelected
          pathPackages
          pathExtras
          envImpure
          envKeep
          ;
      }
      ''
        set -eu
        set -o pipefail


        EVALUATE=false
        KEEP_GOING=false
        EXCLUDE_ARGS=()
        QUERY_ANSWER=

        ERR_REGEX="^Babel evaluation exited with code [1-9][0-9]*"
        ERR_REGEX="$ERR_REGEX|^Error: user-error"
        ERR_REGEX="$ERR_REGEX|^Error: error"

        print_usage()
        {
            "${coreutils}/bin/cat" - <<EOF
        USAGE: ${progName} [OPTION]...  [FILE]...

        DESCRIPTION:

            Uses Emacs to export Org-mode files to GitHub Flavored
            Markdown, which are written to sibling ".md" files.  If no
            files are specified, then all '*.org' files found recursively
            from the current working directory are used instead.

        OPTIONS:

            -h --help            print this help message
            -e --evaluate        evaluate all SRC blocks before exporting
            -E --no-evaluate     don't evaluate before exporting (default)
            -x --exclude PATTERN exclude matched when searching
            -k --keep-going      don't stop if Babel executes non-zero
            -K --no-keep-going   stop if Babel executes non-zero (default)
            -y --yes             answer "yes" to all queries for evaluation
            -n --no              answer "no" to all queries for evaluation

            Recommended usage is with a clean environment using Nix to
            control the PATH.  This helps make executed source blocks more
            deterministic.

            If using both '-e' and '-E' options the last one is overriding
            (useful for automation/defaults).

            Note, the '-e' option evaluates the Org-mode file in-place.
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
                -k|--keep-going)
                    KEEP_GOING="true"
                    ;;
                -K|--no-keep-going)
                    KEEP_GOING="false"
                    ;;
                -y|--yes)
                    QUERY_ANSWER=yes
                    ;;
                -n|--no)
                    QUERY_ANSWER=no
                    ;;
                -x|--exclude)
                    if [ -z "''${2:-}" ]
                    then die "$1 requires argument"
                    fi
                    EXCLUDE_ARGS+=(--exclude "''${2:-}")
                    shift
                    ;;
                --)
                    break
                    ;;
                -*)
                    die "$1 not a valid argument"
                    ;;
                *)
                    break
                    ;;
                esac
                shift
            done

            if [ -n "$QUERY_ANSWER" ]
            then "${coreutils}/bin/yes" "$QUERY_ANSWER" | generate_gfm "$@"
            else generate_gfm "$@"
            fi
        }

        generate_gfm()
        {
            if [ "$#" -gt 0 ]
            then generate_gfm_args "$@"
            else generate_gfm_found
            fi
        }

        generate_gfm_args()
        {
            for f in "$@"
            do generate_gfm_file "$f"
            done
        }

        generate_gfm_found()
        {
            {
                "${fd}/bin/fd" '[.]org$' "''${EXCLUDE_ARGS[@]}" \
                | {
                    while read -r f
                    do generate_gfm_file "$f" <&3
                    done
                }
            } 3<&0
        }

        generate_gfm_file()
        {
            local filepath="$1"
            local eval_options=()
            remove_markdown "$filepath"
            if [ "$EVALUATE" = true ]
            then
                eval_options+=(
                    --eval "(org2gfm-log \"EVALUATING\")"
                    --funcall org-babel-execute-buffer
                    --funcall save-buffer
                )
            fi
            while read -r line
            do
                echo "$line"
                "$KEEP_GOING" \
                    || "${gnugrep}/bin/grep" --perl-regexp --invert-match --quiet \
                        "$ERR_REGEX" <(echo "$line")
            done < <("${emacsWithPkgs}/bin/emacs" \
                --batch \
                --kill \
                --load ${init} \
                --file "$filepath" \
                "''${eval_options[@]}" \
                --eval "(org2gfm-log \"EXPORTING\")" \
                --funcall org-gfm-export-to-markdown 2>&1
            )
        }

        remove_markdown()
        {
            local filepath="$1"
            if [[ "$filepath" =~ \.org$ ]]
            then
                local md_path="''${filepath/%.org/.md}"
                if [ -e "$md_path" ]
                then
                    printf "\n%s\n" "REMOVING: $md_path" >&2
                    rm "$md_path"
                fi
            fi
        }


        main "$@"
      '';

in

{

  /**
    Creates a shell script executable for exporting Org-mode files to
    GitHub-flavored Markdown (GFM).  Run-time CLI options control the script,
    and function arguments statically control the environment it runs in.

    # Example

    ```nix
    # Basic usage with default settings
    org2gfm { }

    # Custom configuration with impure environment
    org2gfm {
      envKeep = [ "LANG" "LOCALE_ARCHIVE" "HOME" ];
    }

    # Include specific packages  and paths in PATH
    org2gfm {
      pathPackages = with pkgs; [ python3 nodejs ];
      pathExtras = [ "/usr/local/bin" ];
    }

    # Resolve the directory putting "nix" on the PATH, and include it
    org2gfm {
      pathImpureSelected = [ "nix" ];
    }
    ```

    # Type

    ```
    org2gfm :: {
      pathImpureAll ? Bool,
      pathImpureSelected ? [String],
      pathPackages ? [Derivation],
      pathExtras ? [String],
      envImpure ? Bool,
      envKeep ? [String]
    } -> Derivation
    ```

    # Arguments

    pathImpureAll
    : Whether to include all paths from the current environment. Defaults to `false`.

    pathImpureSelected
    : Names of executables to include the paths of from the current environment. Defaults to `[]`.

    pathPackages
    : List of Nix packages to include in the PATH. Defaults to `[]`.

    pathExtras
    : Additional paths to include in the PATH. Defaults to `[]`.

    envImpure
    : Whether to use the current environment when running the tool. Defaults to `false` for maximum hermeticity.

    envKeep
    : List of environment variable names to preserve from the current environment. Defaults to `["LANG" "LOCALE_ARCHIVE"]`.

    # Returns

    A derivation that produces a shell script executable named `org2gfm` which
    runs the Org-mode to GFM conversion with the specified environment and PATH
    configuration.
  */
  inherit org2gfm;

  org2gfm-impure = org2gfm {
    pathImpureAll = true;
    envImpure = true;
  };

}
