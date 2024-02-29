- [About this document](#sec-1)
  - [How this project uses Nix](#sec-1-1)
- [Prerequisites](#sec-2)
- [Working with Nix](#sec-3)
  - [Nix files](#sec-3-1)
  - [Inspecting this project for packages](#sec-3-2)
  - [Inspecting other projects for packages](#sec-3-3)
  - [Building packages](#sec-3-4)
  - [Running commands in a shell](#sec-3-5)
  - [Running executables](#sec-3-6)
  - [Shells with remote packages](#sec-3-7)
  - [Installing and uninstalling programs](#sec-3-8)
  - [Garbage collection](#sec-3-9)
- [Next steps](#sec-4)


# About this document<a id="sec-1"></a>

This document explains how to take advantage of software provided by Nix for people new to [the Nix package manager](https://nixos.org/nix). This guide uses this project for examples but focuses on introducing general Nix usage, which applies to other projects using Nix.

This project supports a still-experimental feature of Nix called *flakes*, which this document shows users how to use <span class="underline">without</span>. [Another document](nix-usage-flakes.md) explains how to do everything illustrated in this document, but with flakes.

> **<span class="underline">NOTE:</span>** If you're new to flakes, please read the provided [supplemental introduction to Nix](nix-introduction.md) to understand the experimental nature of flakes and how it may or may not affect you. Hopefully, you'll find these trade-offs acceptable to take advantage of the improved experience flakes offer.

Although this document avoids enabling the experimental flakes feature, it encourages some usage of the “nix-command” experimental feature. This feature exposes a variety of subcommands on the `nix` command-line tool. These subcommands have been widely used and are considered safe. However, as still marked as experimental, their input parameters or output formats are subject to change. Be aware when scripting against them.

This document only uses these experimental `nix` subcommands when there exists no other alternatives, or when the alternatives are considered worse for new users.

## How this project uses Nix<a id="sec-1-1"></a>

This project uses Nix to download all necessary dependencies and build everything from source. In this regard, Nix is helpful as not just a package manager but also a build tool. Nix helps us get from raw source files to built executables in a package we can install with Nix.

Within this project, the various files with a `.nix` extension are Nix files, each of which contains an expression written in the [Nix expression language](https://nixos.org/manual/nix/stable/language/index.html) used by the Nix package manager to specify packages. If you get proficient with this language, you can use these expressions as a starting point to compose your own packages beyond what's provided in this project.

# Prerequisites<a id="sec-2"></a>

If you're new to Nix consider reading the provided [introduction](nix-introduction.md).

This project supports

-   Linux on x86-64 machines
-   MacOS on x86-64 machines
-   MacOS on ARM64 machines (M1 or M2).

That may affect your ability to follow along with examples.

Otherwise, see the provided [Nix installation and configuration guide](nix-installation.md) if you have not yet set Nix up.

To continue following this usage guide, you won't need Nix's experimental flakes feature enabled.

# Working with Nix<a id="sec-3"></a>

Though comprehensively covering Nix is beyond the scope of this document, we'll go over a few commands illustrating some usage of Nix with this project.

## Nix files<a id="sec-3-1"></a>

As [the introduction](nix-introduction.md) mentions, Nix builds are specified by *Nix expressions* written in the Nix programming language and saved in files with a `.nix` extension. These *Nix files* can be collocated with the source they build and package, but this isn't necessary or always the case. Some Nix files retrieve all the source or dependencies they need from the internet.

Various Nix commands accept file paths to Nix files as arguments. If a file path is a directory, a file named `default.nix` is referenced within.

## Inspecting this project for packages<a id="sec-3-2"></a>

This project has a `default.nix` file at its root. This file contains a Nix expression allowing users to access this project's flake outputs (defined in `flake.nix`) without enabling the experimental flakes feature. Using the `default.nix` file instead of using the flake directly comes at the cost of some extra time evaluating the expression.

The Nix expressions of projects often evaluate to *attribute* trees of packages. We can select out these packages by traversing an *attribute path*. These attribute paths are dot-delimited.

The non-experimental way of exploring what's in a Nix expression is to load it into a [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop) session and to tab-complete through the various attributes of the tree:

```sh
nix repl --file .
```

Using the `--file` switch tells `nix repl` to load attributes from a Nix file. If the Nix expression in this file evaluates to an attribute set (a map of attribute names to values), the attributes of this set are bound to variables within the REPL session. Nested attribute sets build up our attribute tree.

Though experimental, the command `nix search` is safe and helpful. Just be aware that input parameters/switches or output formatting might change with later releases if you script using it.

We can use an `--extra-experimental-features nix-command` switch to use an experimental feature with `nix` for a single call. Putting this all together, this is how we'd search the provided `default.nix` file:

```sh
nix --extra-experimental-features nix-command search --file . ''
```

    * legacyPackages.aarch64-darwin.ci
    
    * legacyPackages.x86_64-darwin.ci
    
    * legacyPackages.x86_64-linux.ci
    
    * packages.aarch64-darwin.nix-scaffold
      Script to scaffold a Nix project
    
    …

If you have disabled the `nix-command` feature, and typing out `nix --extra-experimental-features nix-command` is too verbose for your tastes, consider setting an alias in your shell such as the following:

```sh
alias nix-new = nix --extra-experimental-features 'nix-command'
```

Passing in `--file .` tells `nix search` to get the attribute tree to search from the `default.nix` file in the current directory. The positional argument is the attribute path to start the search from within this tree. An empty string indicates to start at the root of the tree.

Note, there are some projects for which `nix search` won't work. These projects require extra approaches to work with `nix search` that are beyond the scope of this document. You can still navigate these projects' attribute tree with `nix repl`. Or you can try to read the source code of the Nix expressions.

We can filter search results down by supplying regexes as an additional position parameters:

```sh
nix --extra-experimental-features nix-command \
    search --file . '' linux org2gfm
```

    * packages.x86_64-linux.org2gfm
      Script to export Org-mode files to GitHub Flavored Markdown (GFM)

We can also use `--json` to get more details about found packages:

```sh
nix --extra-experimental-features \
    nix-command search --json --file . '' | jq .
```

    {
      "legacyPackages.aarch64-darwin.ci": {
        "description": "",
        "pname": "nix-project-ci",
        "version": ""
      },
      "legacyPackages.x86_64-darwin.ci": {
        "description": "",
        "pname": "nix-project-ci",
    …

Additional data includes the package's name (from the “pname” field), a version string, and a textual description of the package.

## Inspecting other projects for packages<a id="sec-3-3"></a>

You may find yourself downloading the source code of projects to inspect Nix files they provide.

Unfortunately, without enabling flakes, you can't use `nix search` with [Nixpkgs](https://github.com/NixOS/nixpkgs), the main repository providing packages for the Nix ecosystem. Without flakes, Nixpkgs has too many packages for Nix to evaluate. You can, though, tab-complete through Nixpkgs with `nix repl --file $LOCAL_NIXPKGS_CHECKOUT`. As an alternative, consider using [NixOS's online search engine](https://search.nixos.org/packages).

If you decide to eventually [try out flakes](nix-usage-flakes.md), you'll find it allows you to comfortably search all projects providing a `flake.nix` file, including Nixpkgs, without even having to clone Git repositories yourself.

This document intentionally doesn't cover the `nix-channel` command or the `NIX_PATH` environment variable. Using either of these legacy features of Nix leads systems to unnecessary unreliability, compromising the reasons to advocate for Nix in the first place. Flakes have a registry system that addresses this problem. If you want to track and access remote repositories without flakes, access them with an explicit checkout of a pinned version/commit.

## Building packages<a id="sec-3-4"></a>

The following result is one returned by an execution of `nix search` or tab-completing from within a `nix repl` session:

    {
      "packages.x86_64-linux.org2gfm": {
        "description": "Script to export Org-mode files to GitHub Flavored Markdown (GFM)",
        "pname": "org2gfm",
        "version": ""
      }
    }

We can see that a package can be accessed with the `packages.x86_64-linux.org2gfm` output attribute path of the project's flake. Not shown in the search results above, this package happens to provide the executable `bin/org2gfm`.

We can build this package with `nix-build` from the project root:

```sh
nix-build --attr packages.x86_64-linux.org2gfm .
```

    /nix/store/c9pxlzsvv5rb40hd21cvhbab825ddcpj-org2gfm

If we omit the path to a Nix file, `nix-build` will try to build `default.nix` in the current directory. If we omit the `--attr` switch and argument, `nix-build` will try to build packages it finds in the root of the attribute tree.

All packages built by Nix are stored in `/nix/store`. Nix won't rebuild packages found there. Once a package is built, its content in `/nix/store` is read-only (until the package is garbage collected, discussed later).

The output of `nix-build` shows us where in `/nix/store` our package has been built. Additionally, as a convenience, `nix-build` creates one or more symlinks for each package requested in the current working directory. These symlinks by default have a name prefixed with “result” and point back to the respective build in `/nix/store`:

```sh
readlink result*
```

    /nix/store/c9pxlzsvv5rb40hd21cvhbab825ddcpj-org2gfm

Following these symlinks, we can see the files the project provides:

```sh
tree -l result*
```

    result
    └── bin
        └── org2gfm
    
    2 directories, 1 file

It's common to configure these “result” symlinks as ignored in source control tools (for instance, for Git within a `.gitignore` file).

`nix-build` has a `--no-out-link` switch in case you want to build packages without creating “result” symlinks.

## Running commands in a shell<a id="sec-3-5"></a>

We can run commands in Nix-curated environments with `nix shell`, provided we're okay enabling the `nix-command` experimental feature. Nix will take executables found in packages, put them in an environment's `PATH`, and then execute a user-specified command.

With `nix shell`, you don't even have to build the package first with `nix build` or mess around with “result” symlinks. `nix shell` will build any necessary packages required.

For example, to get the help message for the `org2gfm` executable provided by the package selected by the `packages.x86_64-linux.org2gfm` attribute path output by this project's flake, we can call the following:

```sh
nix --extra-experimental-features 'nix-command' \
    shell \
    --file . \
    packages.x86_64-linux.org2gfm \
    --command org2gfm --help
```

    USAGE: org2gfm [OPTION]...  [FILE]...
    
    DESCRIPTION:
    
        Uses Emacs to export Org-mode files to GitHub Flavored
    …

Like other Nix commands, using `--file .` tells `nix shell` to read a Nix expression from `./default.nix`. The positional arguments when calling `nix shell` with `--file` are the attribute paths selecting packages to put on the `PATH`.

Note, if you don't use the `--file` switch, `nix shell` will assume you are working with a flake.

The command to run within the shell is specified after the `--command` switch. `nix shell` runs the command in a shell set up with a `PATH` environment variable, including all the `bin` directories provided by the selected packages.

If you want to enter a shell with the set up `PATH`, you can drop the `--command` switch and following arguments.

`nix shell` also supports an `--ignore-environment` flag that restricts `PATH` to only packages selected, rather than extending the `PATH` of the caller's environment. With `--ignore-environment`, the invocation is more sandboxed.

## Running executables<a id="sec-3-6"></a>

The `nix run` command allows us to run executables from packages with a more concise syntax than `nix shell` with a `--command` switch. Like `nix search`, and `nix shell`, this requires enablement of the experimental `nix-command` feature.

Different from what `nix shell` does, `nix run` detects which executable to run from a package. `nix run` assumes the specified package provides an executable with the same name as the package.

Remember, the package's *name* is not the same as the *attribute* used to select a package. The name is package metadata not shown by the default output of `nix search`, but we can get to it by using `--json`:

```sh
nix --extra-experimental-features \
    nix-command search --file . '' --json 'packages.x86_64-linux.org2gfm' | jq .
```

    {
      "packages.x86_64-linux.org2gfm": {
        "description": "Script to export Org-mode files to GitHub Flavored Markdown (GFM)",
        "pname": "org2gfm",
        "version": ""
      }
    }

The “pname” field in the JSON above indicates the package's name. In practice, this name may differ from the last attribute in the attribute path. As detailed in `man nix3-run`, `nix run` may alternatively detect the executable to run from a “name” or a “meta.mainProgram” field.

Here's an example of calling `nix run` with this project:

```sh
nix --extra-experimental-features nix-command \
    run --file . packages.x86_64-linux.org2gfm -- --help
```

    USAGE: org2gfm [OPTION]...  [FILE]...
    
    DESCRIPTION:
    
        Uses Emacs to export Org-mode files to GitHub Flavored
    …

This works because the package selected by `packages.x86_64-linux.org2gfm` selects a package with name “org2gfm” that is the same as the executable provided at `bin/org2gfm`.

If we want something other than what can be detected, then we have to continue using `nix shell` with `--command`.

## Shells with remote packages<a id="sec-3-7"></a>

The previous sections show how to use `nix run` and `nix shell` to run commands in an environment that includes packages from a project local to our filesystem.

We can reference remote projects that have a `default.nix` file using URLs with the `--file` switch. For example, here we reference a tarball of the 23.11 release of Nixpkgs:

```sh
nix --extra-experimental-features 'nix-command' \
    run \
    --file https://github.com/NixOS/nixpkgs/archive/23.11.tar.gz \
    hello
```

    Hello, world!

Downloads from URLs are cached. In case you feel the URL you've downloaded from has changed, use the `--refresh` switch with your invocation.

Since we can only specify one `--file` switch, we can't make a shell with packages from multiple Nix projects. This is possible with flakes enabled, discussed in the companion [usage guide for flakes](nix-usage-flakes.md).

Note the documentation in this project steers people away from `nix-shell`, which provides some conveniences at the expense of compromising reproducible builds. Specifically, `nix-shell` reads from the `NIX_PATH` environment variable. Allowing an environment variable like `NIX_PATH` to affect build results has largely been deemed a mistake by the Nix community. Flakes provide the convenience of `nix-shell` but with better tracking mutable references called *flake registries*.

## Installing and uninstalling programs<a id="sec-3-8"></a>

We've seen that we can build programs with `nix-build` and execute them using the “result” symlink (`result/bin/*`). Additionally, we've seen that you can run programs with `nix shell` and `nix run`. But these additional steps and switches/arguments can still feel extraneous. It would be nice to have the programs on our `PATH`. This is what `nix-env` is for.

`nix-env` maintains a symlink tree, called a *profile*, of installed programs. The active profile is pointed to by a symlink at `~/.nix-profile`. By default, this profile points to `/nix/var/nix/profiles/per-user/$USER/profile`. But you can point your `~/.nix-profile` to any writable location with the `--switch-profile` switch:

```sh
nix-env --switch-profile /nix/var/nix/profiles/per-user/$USER/another-profile
```

This way, you can just put `~/.nix-profile/bin` on your `PATH`, and any programs installed in your currently active profile will be available for interactive use or scripts.

To install the `org2gfm` executable, which is provided by the `packages.x86_64-linux.org2gfm` attribute path, we'd run the following:

```sh
nix-env --install --file . --attr packages.x86_64-linux.org2gfm 2>&1
```

    installing 'org2gfm'
    building '/nix/store/hs9xz17vlb2m4qn6kxfmccgjq4jyrvqg-user-environment.drv'...

We can see this installation by querying what's been installed:

```sh
nix-env --query
```

    org2gfm

Note that this name we see in the results of `nix-env` is the package name, not the attribute path we used to select our packages. Sometimes, they are congruent, but not always.

We can see the package name of anything we install by using `nix search` with a `--json` switch to get more details:

```sh
nix --extra-experimental-features nix-command \
    search --json --file . '' linux 'org2gfm'
```

    {
      "packages.x86_64-linux.org2gfm": {
        "description": "Script to export Org-mode files to GitHub Flavored Markdown (GFM)",
        "pname": "org2gfm",
        "version": ""
      }
    }

And if we want to uninstall a program from our active profile, we do so by the package's name (“pname” above), in this case “org2gfm”:

```sh
nix-env --uninstall org2gfm 2>&1
```

    uninstalling 'org2gfm'

Summarizing what we've done, we've installed our package using its attribute path (`packages.x86_64-linux.org2gfm`) within the referenced Nix expression. But we uninstall it using the package name (“org2gfm”), which may not be the same as the attribute path. When a package is installed, Nix keeps no reference to the expression evaluated to obtain the installed package's derivation. The attribute path is only relevant to this expression. In fact, two different expressions could evaluate to the same derivation, but use different attribute paths. This is why we uninstall packages by their package name.

Also, if you look at the symlink-resolved location for your profile, you'll see that Nix retains the symlink trees of previous generations of your profile. You can even roll back to an earlier profile with the `--rollback` switch. You can also delete old generations of your profile with the `--delete-generations` switch.

## Garbage collection<a id="sec-3-9"></a>

Every time you build a new version of your code, it's stored in `/nix/store`. There is a command called `nix-collect-garbage` that purges unneeded packages. Programs that should not be removed by `nix-collect-garbage` can be found by starting with symlinks stored as *garbage collection (GC) roots* under three locations:

-   `/nix/var/nix/gcroots`
-   `/nix/var/nix/profiles`
-   `/nix/var/nix/manifests`.

For each package, Nix is aware of all files that reference back to other packages in `/nix/store`, whether in text files or binaries. This dependency tracking helps Nix ensure that dependencies of packages reachable from GC roots won't be deleted by garbage collection.

Each “result” symlink created by a `nix-build` invocation has a symlink in `/nix/var/nix/gcroots/auto` pointing back to it. So we've got symlinks in `/nix/var/nix/gcroots/auto` pointing to “result” symlinks in our projects, which then reference the actual built project in `/nix/store`. These chains of symlinks prevent packages built by `nix-build` from being garbage collected.

If you want a package you've built with `nix-build` to be garbage collected, delete the “result” symlink created before calling `nix store gc`. Breaking symlink chains under `/nix/var/nix/gcroots` removes protection from garbage collection. `nix-collect-garbage` will clean up broken symlinks when it runs.

Everything under `/nix/var/nix/profiles` is also considered a GC root. This is why users, by convention, use this location to store their Nix profiles with `nix-env`.

Also, note that if you delete a “result\*” link and call `nix-collect-garbage`, though some garbage may be reclaimed, you may find that an old profile keeps the program alive. Use `nix-collect-garbage`'s `--delete-old` switch to delete old profiles (it just calls `nix-env --delete-generations` on your behalf).

It's also good to know that `nix-collect-garbage` won't delete packages referenced by any running processes. In the case of `nix run` no garbage collection root symlink is created under `/nix/var/nix/gcroots`, but while `nix run` is running `nix-collect-garbage` won't delete packages needed by the running command. However, once the `nix run` call exits, any packages pulled from a substituter or built locally are candidates for deletion by `nix-collect-garbage`. If you called `nix run` again after garbage collecting, those packages may be pulled or built again.

# Next steps<a id="sec-4"></a>

This document has covered a fraction of Nix usage, hopefully enough to introduce Nix in the context of [this project](../README.md).

An obvious place to start learning more about Nix is [the official documentation](https://nixos.org/learn.html).

Bundled with this project is [a small tutorial on the Nix language](nix-language.md). It's also not bad to know [how to use this project with flakes](nix-usage-flakes.md). Flakes are broadly used in the Nix ecosystem, and will become the standard.

All the commands we've covered have more switches and options. See the respective man pages for more.

We didn't cover much of [Nixpkgs](https://github.com/NixOS/nixpkgs), the gigantic repository of community-curated Nix expressions.

The Nix ecosystem is vast. This project and documentation illustrate only a small sample of what Nix can do.
