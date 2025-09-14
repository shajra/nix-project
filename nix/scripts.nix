{
  coreutils,
  lib,
  runtimeShell,
  shellcheck,
  stdenv,
  writeTextFile,
}:

let
  runtimeShell' = runtimeShell;
in

rec {

  writeShellChecked =
    name:
    {
      meta ? { },
      executable ? false,
      destination ? "",
    }:
    body:
    let
      checkPhase = ''
        ${stdenv.shell} -n $out${destination}
        "${shellcheck}/bin/shellcheck" -x "$out${destination}"
      '';
      args = {
        inherit
          name
          executable
          destination
          checkPhase
          ;
        text = body;
      };
    in
    (writeTextFile args).overrideAttrs (old: {
      meta = old.meta or { } // meta;
    });

  writeShellCheckedExe =
    name:
    {
      meta ? { },
      exeName ? name,
      runtimeShell ? runtimeShell',
      envCleaned ? true,
      envKeep ? [
        "LANG"
        "LOCALE_ARCHIVE"
      ],
      pathCleaned ? true,
      pathKeep ? [ ],
      pathPackages ? [ ],
      pathExtras ? [ ],
    }:
    body:
    let
      destination = "/bin/${exeName}";
      pathComponents =
        (lib.optionals (pathPackages != [ ]) [ (lib.makeBinPath pathPackages) ])
        ++ (lib.optionals (pathExtras != [ ]) [ (lib.concatStringsSep ":" pathExtras) ])
        ++ (lib.concatMap (exe: [ ''$(path_for "$(command -v ${exe})")'' ]) pathKeep)
        ++ (lib.optionals (!pathCleaned) [ "$PATH" ]);
      pathExport = ''
        # DESIGN: Dynamically constructed PATH has allowable corner cases
        # shellcheck disable=SC2123 disable=SC2269
        ${"PATH=\"" + lib.concatStringsSep ":" pathComponents + "\""}
        export PATH
      '';
      envCleanedArgs =
        "--ignore-environment "
        + lib.concatStringsSep " " (map (var: ''"${var}=$'' + ''{${var}:-}"'') envKeep)
        + " PATH=\"$PATH\"";
      scriptArgs = {
        inherit meta destination;
        executable = true;
      };
      scriptBase = writeShellChecked name scriptArgs ''
        #!${runtimeShell}
        . "${scriptCommon}/share/nix-project/common.sh"
        ${lib.optionalString (!envCleaned) pathExport}
        ${body}
      '';
      scriptEnvCleaned = writeShellChecked (name + "-env") scriptArgs ''
        #!${runtimeShell'}
        . "${scriptCommon}/share/nix-project/common.sh"
        ${pathExport}
        exec "${coreutils}/bin/env" ${envCleanedArgs} "${scriptBase}${destination}" "$@"
      '';
    in
    if envCleaned then scriptEnvCleaned else scriptBase;

  writeShellCheckedShareLib =
    name: packagePath:
    {
      meta ? { },
      baseName ? name,
      dialect ? "sh",
    }:
    body:
    writeShellChecked name
      {
        inherit meta;
        executable = false;
        destination = "/share/${packagePath}/${baseName}.${dialect}";
      }
      ''
        # shellcheck shell=${dialect}

        ${body}
      '';

  scriptCommon =
    writeShellCheckedShareLib "nix-project-lib-common" "nix-project"
      {
        # DESIGN: keeping these POSIX-compliant so they can be used in Dash
        # scripts as well.  If functions that really need Bash come up, they
        # can go in another common module.
        meta.description = "Common POSIX-compliant functions";
        baseName = "common";
      }
      ''
        add_nix_to_path()
        {
            if [ -x "$1" ] \
                && [ "$("${coreutils}/bin/basename" "$1")" = "nix" ]
            then PATH="$(path_for "$1"):$PATH"
            else die "invalid file path of 'nix' executable: $1"
            fi
            export PATH
        }

        path_for()
        {
            "${coreutils}/bin/dirname" \
                "$("${coreutils}/bin/readlink" --canonicalize "$1")"
        }

        die()
        {
            print_usage >&2
            die_helpless "$1"
        }

        die_helpless()
        {
            echo
            echo "ERROR: $1" >&2
            exit 1
        }
      '';

}
