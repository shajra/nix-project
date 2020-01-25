- [About this project](#sec-1)
  - [Motivation to use Nix](#sec-1-1)
  - [Managing dependencies with Nix and Niv](#sec-1-2)
  - [Documenting with Emacs Org-mode](#sec-1-3)
- [Usage](#sec-2)
  - [Install Nix](#sec-2-1)
  - [Scaffolding](#sec-2-2)
  - [Managing dependencies](#sec-2-3)
  - [Evaluating/exporting documentation](#sec-2-4)
  - [GitHub rate limiting of Niv calls](#sec-2-5)
  - [Next steps](#sec-2-6)
- [Release](#sec-3)
- [License](#sec-4)
- [Contribution](#sec-5)

[![img](https://img.shields.io/travis/shajra/nix-project/master.svg?label=master)](https://travis-ci.org/shajra/nix-project)

# About this project<a id="sec-1"></a>

This project assists the setup of other projects with the [Nix package manager](https://nixos.org/nix). Specifically, it provides two scripts:

-   `nix-project` to help scaffold a Nix-based project and update dependencies with [Niv](https://github.com/nmattia/niv).
-   `org2gfm` to generate [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/) from [Emacs Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html) files.

You can use this project directly (the author does). But it's also not a lot of code. So you could just borrow ideas from it for your own projects.

## Motivation to use Nix<a id="sec-1-1"></a>

When making a new software project, wrangling dependencies can be a chore. For instance, Makefiles can call external dependencies that may or may not be on a system. The same applies to tools for generating documentation.

Nix can build and install projects in a way that's precise, repeatable, and guaranteed not to conflict with anything already installed. Nix can even concurrently provide multiple versions of any dependency without conflicts.

Furthermore, Nix supports building a variety of languages and can provide tooling to integrate them into new packages. In many cases, Nix picks up where language-specific tooling stops, layering on top of the tools and techniques we're already familiar with.

All of this makes Nix an attractive tool for managing almost any software project.

## Managing dependencies with Nix and Niv<a id="sec-1-2"></a>

One of the benefits of Nix is that it pins our dependencies to specific versions. When they are downloaded, they are parity checked with an explicitly provided hash. Because each new version of each dependency requires a new hash, maintaining these hashes can be a chore, especially when upgrading many dependencies to their latest versions.

Fortunately, a tool called [Niv](https://github.com/nmattia/niv) provides a command-line tool `niv` to make upgrading dependencies a single command.

You could use `niv` directly, but it has some dependencies it expects to be already installed. Although not often a problem, Niv's reliance on preexisting installations isn't in the spirit of Nix. We want Nix to download all dependencies for us. That's why we're using Nix in the first place.

The `nix-project` script provided by this project wraps `niv` such that all the dependencies it needs are provided by Nix. It can also help scaffold a new project to use all the scripts provided by this project.

## Documenting with Emacs Org-mode<a id="sec-1-3"></a>

In addition to building and distributing a project, we often want to document it as well. Good documentation often has example snippets of code and output/results. Ideally, these snippets of documentation can be generated with automation, so that they reflect the code in the project. This leads to some form of [literate programming](https://en.wikipedia.org/wiki/Literate_programming).

The state of literate programming is not that advanced in general. However, [Emacs' Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html) has some fairly compelling features in the spirit of literate programming. With Org-mode, we can evaluate code blocks and inject the results in blocks right below the code. And this all can then be exported to the format of our choice.

Manually managing an Emacs installation, including requisite plugins, is historically hard to do consistently and portably. Fortunately, Nix can install in a precisely configured Emacs as a dependency without conflicting with any installations of Emacs already on a system.

The `org2gfm` script orchestrates Nix's configuration, installation, and execution of Emacs to generate our documentation. Emacs is run in a headless mode by `org2gfm`, so the fact we're using Emacs at all is hidden.

Note that as its name implies `org2gfm` only generates [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/) from Org-mode files. This is currently all the author needs for projects already hosted on GitHub.

# Usage<a id="sec-2"></a>

## Install Nix<a id="sec-2-1"></a>

> **<span class="underline">NOTE:</span>** You don't need this step if you're running NixOS, which comes with Nix baked in.

If you don't already have Nix, the official installation script should work on a variety of GNU/Linux distributions, and also Mac OS. The easiest way to run this installation script is to execute the following shell command as a user other than root:

```shell
curl https://nixos.org/nix/install | sh
```

This script will download a distribution-independent binary tarball containing Nix and its dependencies, and unpack it in `/nix`.

If you prefer to install Nix another way, reference the [Nix manual](https://nixos.org/nix/manual/#chap-installation)

## Scaffolding<a id="sec-2-2"></a>

This project actually uses both the `nix-project` and `org2gfm` scripts itself. You'll find usage of both of these scripts in the [./support](./support) directory. The `support/dependencies-upgrade` script delegates to `nix-project`, and `support/docs-generate` delegates to `org2gfm`.

If you call `dependencies-upgrade` (no arguments needed) it will upgrade all its dependencies, which are specified in the [./nix/sources.json](./nix/sources.json) file. And similarly, if you call `docs-generate` (again with no arguments) all the Org-mode files will be re-evaluated and re-exported to GFM files.

If you want to scaffold a new project with these scripts, you can create a new directory, go into it, and invoke the following `nix` call:

```shell
nix run \
    --file http://github.com/shajra/nix-project/tarball/master \
    nix-project-exe --ignore-environment \
    --command nix-project --scaffold --nix `command -v nix`
```

For those new to Nix, this command downloads a tarball of this project hosted on GitHub, and evaluates the `default.nix` file in its root. This file provides some packages, and we're selecting the `nix-project-exe` one. The `--ignore-environment` switch is extra, and just ensures that our invocation of `nix run` is sandboxed and doesn't accidentally reference binaries on our `PATH`. The `nix-project-exe` package provides a `nix-project` script, which we call with the arguments following the `--command` switch. We tell `nix-project` to scaffold our empty directory with the `--scaffold` switch. And finally, we use the `--nix` switch to indicate which `nix` executable to use. We use Nix to pull in dependencies, but it is not recommended to use a different version of Nix than is installed on the system. So we allow references outside our sandboxed environment for just Nix itself.

In the freshly scaffolded project, you'll see the following files:

    ├── nix
    │   ├── default.nix
    │   ├── sources.json
    │   └── sources.nix
    ├── README.org
    └── support
        ├── dependencies-upgrade
        └── docs-generate

`nix/sources.json` and `nix/sources.nix` are modified directly by Niv (via `nix-project` via `dependencies-upgrade`), but the rest of the files are yours to modify as you see fit.

## Managing dependencies<a id="sec-2-3"></a>

The scripts in the `support` directory are mostly calls to `nix run`, similarly to what we called for scaffolding, except they reference dependencies specified in `nix/sources.json` rather than going to GitHub directly.

In your newly scaffolded project, you can call `dependencies-upgrade` with no arguments to upgrade all your dependencies. But it will likely do nothing, because a freshly scaffolded project already has the latest dependencies.

See the [Niv](https://github.com/nmattia/niv) documentation on how to manage dependencies. You can run Niv commands directly with `dependencies-upgrade`. For example, to run the equivalent of `niv show` you can run

```shell
support/dependencies-upgrade --niv -- show
```

You can also use `dependencies-upgrade` to see the help messages for both `nix-project` and `niv`.

Using the `--help` switch directly with `dependencies-upgrade` shows the help for `nix-project`, which it delegates to.

```shell
support/dependencies-upgrade --help
```

    USAGE:
    
        nix-project [OPTION]... --scaffold
        nix-project [OPTION]... --upgrade
        nix-project [OPTION]... --niv -- COMMAND...
    
    DESCRIPTION:
    
        A wrapper of Niv for managing Nix dependencies to assure
        dependencies Niv uses are pinned with Nix.  Also provides a
        '--scaffold' command to set up an directory as a project
        using 'nix-project'.
    
        If multiple commands or switches are specified, the last one
        is used.
    
    COMMANDS:
    
        -s, --scaffold  set up current directory with example scripts
        -u, --upgrade   upgrade dependencies with Niv
        -n, --niv       pass arguments directly to Niv
    
        Note '--upgrade' runs the following in one step:
    
    	niv init; niv update
    
    OPTIONS:
    
        -h, --help             print this help message
        -t, --target-dir DIR   directory of project to manage
    			   (default: current directory)
        -S, --source-dir DIR   directory relative to target for
    			   Nix files (default: nix)
        -g, --github-token     file with GitHub API token (default:
    			   ~/.config/nix-project/github.token)
        -N, --nix              filepath of 'nix' executable to use
    
        'nix-project' pins all dependencies except for Nix itself,
         which it finds on the path if possible.  Otherwise set
         '--nix'.

Since `nix-project` can pass through commands to `niv` we can see the help for Niv with the following command:

```shell
support/dependencies-upgrade --niv -- --help
```

    niv - dependency manager for Nix projects
    
    version: 0.2.12
    
    Usage: niv [-s|--sources-file FILE] COMMAND
    
    Available options:
      -s,--sources-file FILE   Use FILE instead of nix/sources.json
      -h,--help                Show this help text
    
    Available commands:
      init                     Initialize a Nix project. Existing files won't be
    			   modified.
      add                      Add a GitHub dependency
      show                     
      update                   Update dependencies
      modify                   Modify dependency attributes without performing an
    			   update
      drop                     Drop dependency

## Evaluating/exporting documentation<a id="sec-2-4"></a>

A freshly scaffolded project will have a `README.org` file in its root. This file has an example call to `whoami` in it. When you call `support/docs-generate`, you'll see that the `README.org` file is modified in place to include the result of the `whoami` call. Additionally, a `README.md` file is exported.

Notice that the `support/docs-generate` script includes the `pkgs.coreutils` package. This is the package that provides the `whoami` executable. You explicitly control what executables are in scope for evaluating your code snippets. `pkgs` provides all the packages that come with the [Nixpkgs repository](https://nixos.org/nixpkgs), but you can always define your own packages.

> **<span class="underline">NOTE</span>**: Since `docs-generate` writes over files in-place, source control is highly recommended to protect against the loss of documentation.

For reference, here's the documentation from the `--help` switch for `docs-generate` / `org2gfm`:

```shell
support/docs-generate --help
```

    USAGE: org2gfm [OPTION]...  [FILE]...
    
    DESCRIPTION:
    
        Uses Emacs to convert Org-mode files to GitHub Flavored
        Markdown, which are written to sibling ".md" files.  If no
        files are specified, then all '*.org' files found recursively
        from the current working directory are used instead.
    
    OPTIONS:
    
        -h, --help          print this help message
        -e, --evaluate      evaluate all SRC blocks
        -E, --no-evaluate   don't evaluate any SRC blocks (default)
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

## GitHub rate limiting of Niv calls<a id="sec-2-5"></a>

Many dependencies managed by Niv may come from GitHub. GitHub will rate limit anonymous API calls to 60/hour, which is not a lot. To increase this limit, you can make a [personal access token](https://github.com/settings/tokens) with GitHub. Then write the generated token value in the file `~/.config/nix-project/github.token`. Make sure to restrict the permissions of this file appropriately.

## Next steps<a id="sec-2-6"></a>

At this point, you can create a skeleton project with dependencies and generate documentation for it. But you need to know more about Nix and the Nix expression language to build your own projects with Nix.

the `nix/default.nix` in the skeleton project derives packages from `sources.json`. You can make more Nix expressions in this directory and reference them in `nix/default.nix`.

See the [Nix manual](https://nixos.org/nix/manual) and [Nixpkgs manual](https://nixos.org/nixpkgs/manual) for more information on making your own Nix expressions using the Nixpkgs repository as a foundation.

# Release<a id="sec-3"></a>

The "master" branch of the repository on GitHub has the latest released version of this code. There is currently no commitment to either forward or backward compatibility.

"user/shajra" branches are personal branches that may be force-pushed to. The "master" branch should not experience force-pushes and is recommended for general use.

# License<a id="sec-4"></a>

All files in this "nix-project" project are licensed under the terms of GPLv3 or (at your option) any later version.

Please see the [./COPYING.md](./COPYING.md) file for more details.

# Contribution<a id="sec-5"></a>

Feel free to file issues and submit pull requests with GitHub.

There is only one author to date, so the following copyright covers all files in this project:

Copyright © 2019 Sukant Hajra
