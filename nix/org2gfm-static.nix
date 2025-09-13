{
  lib,
  nix-project-lib,
}:

/**
  Creates a fully parameterized "org2gfm" script.

  Function arguments completely specify not only how to run "org2gfm," but also
  how to constrain the environment it runs in.  Further CLI options can be
  provided for overriding.

  # Example

  ```nix
  # Basic usage with default settings
  org2gfm-static { }

  # Custom configuration with evaluation enabled
  org2gfm-static {
    evaluate = true;
    exclude = [ "tmp-*" ];
  }

  # Preserve specific environment variables
  org2gfm-static {
    envImpure = true;
    envKeep = [ "LANG" "LOCALE_ARCHIVE" "HOME" ];
  }
  ```

  # Type

  ```
  org2gfm-static :: {
    envImpure ? Bool,
    envKeep ? [String],
    pathImpureAll ? Bool,
    pathImpureSelected ? [String],
    pathPackages ? [Derivation],
    pathExtras ? [String],
    evaluate ? Bool,
    exclude ? [String],
    keepGoing ? Bool,
    alwaysYes ? Bool,
    alwaysNo ? Bool
  } -> Derivation
  ```

  # Arguments

  envImpure
  : Whether to use the current environment when running the tool. Defaults to `false` for maximum hermeticity.

  envKeep
  : List of environment variable names to preserve from the current environment. Defaults to `["LANG" "LOCALE_ARCHIVE"]`.

  pathImpureAll
  : Whether to include all paths from the current environment. Defaults to `false`.

  pathImpureSelected
  : List of specific paths to include from the current environment. Defaults to `[]`.

  pathPackages
  : List of Nix packages to include in the PATH. Defaults to `[]`.

  pathExtras
  : Additional paths to include in the PATH. Defaults to `["/bin" "/usr/bin"]`.

  evaluate
  : Whether to evaluate Org-mode code blocks during conversion. Defaults to `true`.

  exclude
  : List of glob patterns for files/directories to exclude from processing. Defaults to `[]`.

  keepGoing
  : Whether to continue processing other files if one fails. Defaults to `false`.

  alwaysYes
  : Whether to automatically answer "yes" to all prompts. Defaults to `false`.

  alwaysNo
  : Whether to automatically answer "no" to all prompts. Defaults to `false`.

  # Returns

  A derivation  providing the `bin/org2gfm` exectuable.
*/
{
  envImpure ? false,
  envKeep ? [
    "LANG"
    "LOCALE_ARCHIVE"
  ],
  pathImpureAll ? false,
  pathImpureSelected ? [ ],
  pathPackages ? [ ],
  pathExtras ? [
    "/bin"
    "/usr/bin"
  ],
  evaluate ? true,
  exclude ? [ ],
  keepGoing ? false,
  alwaysYes ? false,
  alwaysNo ? false,
}:

let

  org2gfmArgs = lib.concatStringsSep " " (
    (if evaluate then [ "--evaluate" ] else [ "--no-evaluate" ])
    ++ (if keepGoing then [ "--keep-going" ] else [ "--no-keep-going" ])
    ++ lib.optionals alwaysYes [ "--yes" ]
    ++ lib.optionals alwaysNo [ "--no" ]
    ++ lib.concatMap (pattern: [
      "--exclude"
      (lib.escapeShellArg pattern)
    ]) exclude
  );

  org2gfm = nix-project-lib.org2gfm {
    inherit
      envImpure
      envKeep
      pathImpureAll
      pathImpureSelected
      pathPackages
      pathExtras
      ;
  };

  meta.description = "Exports Org-mode files to GitHub Flavored Markdown (GFM) in a controlled environment";

in

nix-project-lib.scripts.writeShellCheckedExe "org2gfm-static"
  {
    exeName = "org2gfm";
    inherit meta;
    envImpure = true;
    pathImpureAll = true;
  }
  ''
    set -eu
    set -o pipefail
    exec "${org2gfm}/bin/org2gfm" ${org2gfmArgs} "$@"
  ''
