{
  lib,
  coreutils,
  nix-project-lib,
  nix-project-org2gfm,
}:

/**
  Exports Org-mode files to GitHub-flavored Markdown (GFM) in a hermetic
  environment.

  # Example

  ```nix
  # Basic usage with default settings
  org2gfm-hermetic { }

  # Custom configuration with evaluation enabled
  org2gfm-hermetic {
    evaluate = true;
    exclude = [ "tmp-*" ];
  }

  # Preserve specific environment variables
  org2gfm-hermetic {
    ignoreEnvironment = true;
    keepEnvVars = [ "LANG" "LOCALE_ARCHIVE" "HOME" ];
  }
  ```

  # Type

  ```
  org2gfm-hermetic :: {
    ignoreEnvironment ? Bool,
    keepEnvVars ? [String],
    pathPackages ? [Derivation],
    extraPaths ? [String],
    pathIncludesActiveNix ? Bool,
    pathIncludesPrevious ? Bool,
    evaluate ? Bool,
    exclude ? [String],
    keepGoing ? Bool,
    alwaysYes ? Bool,
    alwaysNo ? Bool
  } -> Derivation
  ```

  # Arguments

  ignoreEnvironment
  : Whether to ignore the current environment when running the tool. Defaults to `true` for maximum hermeticity.

  keepEnvVars
  : List of environment variable names to preserve from the current environment. Defaults to `["LANG" "LOCALE_ARCHIVE"]`.

  pathPackages
  : List of Nix packages to include in the PATH. Defaults to `[]`.

  extraPaths
  : Additional paths to include in the PATH. Defaults to `["/bin" "/usr/bin"]`.

  pathIncludesActiveNix
  : Whether to include the active Nix environment in the PATH. Defaults to `false`.

  pathIncludesPrevious
  : Whether to carry over the previous environment's PATH into the new PATH. Defaults to `false`.

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

  A derivation that produces a shell script executable named `org2gfm-hermetic` which
  runs the `org2gfm` tool in a hermetic environment with the specified configuration.
*/
{
  ignoreEnvironment ? true,
  keepEnvVars ? [
    "LANG"
    "LOCALE_ARCHIVE"
  ],
  pathPackages ? [ ],
  extraPaths ? [
    "/bin"
    "/usr/bin"
  ],
  pathIncludesActiveNix ? false,
  pathIncludesPrevious ? false,
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

  envArgs =
    lib.optionalString ignoreEnvironment "--ignore-environment "
    + lib.concatStringsSep " " (map (var: ''"${var}=$'' + ''{${var}:-}"'') keepEnvVars)
    + " PATH=\"$PATH\"";

  progName = "org2gfm-hermetic";
  meta.description = "Exports Org-mode files to GitHub Flavored Markdown (GFM) in a hermetic environment";

in

nix-project-lib.scripts.writeShellCheckedExe progName
  {
    inherit
      meta
      pathIncludesPrevious
      pathIncludesActiveNix
      pathPackages
      extraPaths
      ;
  }
  ''
    set -eu
    set -o pipefail
    exec "${coreutils}/bin/env" ${envArgs} \
      "${nix-project-org2gfm}/bin/org2gfm" ${org2gfmArgs} "$@"
  ''
