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
      path ? null,
      pathPure ? true,
    }:
    body:
    let
      pathSuffix = if pathPure then "" else ":$PATH";
      pathDecl = if (path == null) then "" else "PATH=\"" + lib.makeBinPath path + pathSuffix + "\"";
    in
    writeShellChecked name
      {
        inherit meta;
        executable = true;
        destination = "/bin/${exeName}";
      }
      ''
        #!${runtimeShell}

        ${pathDecl}

        ${body}
      '';

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
