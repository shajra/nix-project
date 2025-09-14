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
    envCleaned = true;
    envKeep = [ "LANG" "LOCALE_ARCHIVE" "HOME" ];
  }
  ```

  # Type

  ```
  org2gfm-static :: {
    envCleaned ? Bool,
    envKeep ? [String],
    pathCleaned ? Bool,
    pathKeep ? [String],
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

  envCleaned
  : Rebuild environment variables from a clean slate. Defaults to `true`.

  envKeep
  : Variables to keep from the current environment. Defaults to `["LANG" "LOCALE_ARCHIVE"]`.

  pathCleaned
  : Rebuild PATH from a clean slate. Defaults to `true`.

  pathKeep
  : Basenames of executables whose paths to include from the current environment. Defaults to `[]`.

  pathPackages
  : Packages to add to the PATH. Defaults to `[]`.

  pathExtras
  : Additional paths to add to the PATH. Defaults to `[]`.

  evaluate
  : Evaluate all SRC blocks in Org files before exporting. Defaults to `true`.

  exclude
  : Glob patterns for files/directories to exclude. Defaults to `[]`.

  keepGoing
  : Whether to ignore failures where possible. Defaults to `false`.

  alwaysYes
  : Whether to automatically answer "yes" to all prompts. Defaults to `false`.

  alwaysNo
  : Whether to automatically answer "no" to all prompts. Defaults to `false`.

  # Returns

  A derivation  providing the `bin/org2gfm` exectuable.
*/
{
  envCleaned ? true,
  envKeep ? [
    "LANG"
    "LOCALE_ARCHIVE"
  ],
  pathCleaned ? true,
  pathKeep ? [ ],
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
      envCleaned
      envKeep
      pathCleaned
      pathKeep
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
    envCleaned = false;
    pathCleaned = false;
  }
  ''
    set -eu
    set -o pipefail
    exec "${org2gfm}/bin/org2gfm" ${org2gfmArgs} "$@"
  ''
