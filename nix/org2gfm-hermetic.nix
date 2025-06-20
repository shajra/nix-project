{
  lib,
  coreutils,
  nix-project-lib,
  nix-project-org2gfm,
}:

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
