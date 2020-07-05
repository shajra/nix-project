- [About this project](#sec-1)
  - [Using Nix](#sec-1-1)
  - [Managing dependencies with Nix and Niv](#sec-1-2)
  - [Documenting with Emacs Org-mode](#sec-1-3)
- [Usage](#sec-2)
  - [Nix package manager setup](#sec-2-1)
  - [Cache setup](#sec-2-2)
  - [Scaffolding](#sec-2-3)
  - [Managing dependencies](#sec-2-4)
  - [Evaluating/exporting documentation](#sec-2-5)
  - [GitHub rate limiting of Niv calls](#sec-2-6)
  - [Next steps](#sec-2-7)
- [Release](#sec-3)
- [License](#sec-4)
- [Contribution](#sec-5)

[![img](https://github.com/shajra/nix-project/workflows/CI/badge.svg)](https://github.com/shajra/nix-project/actions)

# About this project<a id="sec-1"></a>

This project assists the setup of other projects with the [Nix package manager](https://nixos.org/nix). Specifically, it provides two scripts:

-   `nix-project` to help scaffold a Nix-based project and update dependencies with [Niv](https://github.com/nmattia/niv).
-   `org2gfm` to generate [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/) from [Emacs Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html) files.

You can use this project directly (the author does). But it's also not a lot of code. So you could just borrow ideas from it for your own projects.

## Using Nix<a id="sec-1-1"></a>

Dependency management is the main problem the `nix-project` and `org2gfm` scripts use Nix to address. A software project can depend on a lot of complicated dependencies from a variety of language ecosystems. These dependencies are needed not only for the project itself, but also to support things like generated documentation.

Nix has a compelling approach that gives us an extremely precise and repeatable dependency management system that covers a broad set of programming language ecosystems.

See [the provided documentation on Nix](doc/nix.md) for more on what Nix is, why we're motivated to use it, and how to get set up with it for this project.

## Managing dependencies with Nix and Niv<a id="sec-1-2"></a>

One of the benefits of Nix is that it pins our dependencies to specific versions. When they are downloaded, they are parity checked with an explicitly provided hash. Because each new version of each dependency requires a new hash, maintaining these hashes can be a chore, especially when upgrading many dependencies to their latest versions.

Fortunately, a tool called [Niv](https://github.com/nmattia/niv) provides a command-line tool `niv` to make upgrading dependencies a single command. Niv tracks downloaded versions of source from locations like GitHub, maintaining metadata of the latest versions and calculated hashes in a `sources.json` file. Since this project uses itself, you can have a look at [this project's `sources.json` file](nix/sources.json) as an example.

You could use `niv` directly, but it has some dependencies it expects to be already installed. Although not often a problem, Niv's reliance on preexisting installations isn't in the spirit of Nix. We want Nix to download all dependencies for us. That's why we're using Nix in the first place.

The `nix-project` script provided by this project wraps `niv` such that all the dependencies it needs are provided by Nix. It can also help scaffold a new project to use all the scripts provided by this project.

## Documenting with Emacs Org-mode<a id="sec-1-3"></a>

In addition to building and distributing a project, we often want to document it as well. Good documentation often has example snippets of code followed by the output of an evaluation/invocation. Ideally, these snippets of output are generated with automation, so that they are congruent with the code in the project. This leads to some form of [literate programming](https://en.wikipedia.org/wiki/Literate_programming).

The state of literate programming is not that advanced in general. However, [Emacs' Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html) has some compelling features in the spirit of literate programming. With Org-mode, we can evaluate code blocks and inject the results inline right below the code. And this all can then be exported to the format of our choice.

Manually managing an Emacs installation, including requisite plugins, is historically hard to do consistently and portably. Fortunately, Nix can install a precisely configured Emacs instance as a dependency without conflicting with any installations of Emacs already on a system.

The `org2gfm` script orchestrates with Nix the configuration, installation, and execution of Emacs to generate our documentation. Emacs is run in a headless mode by `org2gfm`, so the fact we're using Emacs at all is hidden.

Note that as its name implies `org2gfm` only generates [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/) from Org-mode files. This is currently all the author needs for projects already hosted on GitHub.

# Usage<a id="sec-2"></a>

This project should work with either GNU/Linux or MacOS operating systems. Just follow the following steps.

## Nix package manager setup<a id="sec-2-1"></a>

> **<span class="underline">NOTE:</span>** You don't need this step if you're running NixOS, which comes with Nix baked in.

If you don't already have Nix, the official installation script should work on a variety of UNIX-like operating systems. The easiest way to run this installation script is to execute the following shell command as a user other than root:

```shell
curl https://nixos.org/nix/install | sh
```

This script will download a distribution-independent binary tarball containing Nix and its dependencies, and unpack it in `/nix`.

The Nix manual describes [other methods of installing Nix](https://nixos.org/nix/manual/#chap-installation) that may suit you more.

## Cache setup<a id="sec-2-2"></a>

It's recommended to configure Nix to use shajra.cachix.org as a Nix *substituter*. This project pushes built Nix packages to [Cachix](https://cachix.org) as part of its continuous integration. Once configured, Nix will pull down these pre-built packages instead of building them locally.

You can configure shajra.cachix.org as a substituter with the following command:

```shell
nix run \
    --file https://cachix.org/api/v1/install \
    cachix \
    --command cachix use shajra
```

This will perform user-local configuration of Nix at `~/.config/nix/nix.conf`. This configuration will be available immediately, and any subsequent invocation of Nix commands will take advantage of the Cachix cache.

If you're running NixOS, you can configure Cachix globally by running the above command as a root user. The command will then configure `/etc/nixos/cachix/shajra.nix`, and the output will explain how to tie this configuration into your normal NixOS configuration.

## Scaffolding<a id="sec-2-3"></a>

This project actually uses both the `nix-project` and `org2gfm` scripts that it provides. You'll find usage of both of these scripts in the [./support](./support) directory. The `support/dependencies-upgrade` script delegates to `nix-project`, and `support/docs-generate` delegates to `org2gfm`.

If you call `dependencies-upgrade` (no arguments needed) it will upgrade all of this project's dependencies, which are specified in the [./nix/sources.json](./nix/sources.json) file. And similarly, if you call `docs-generate` (again with no arguments) all the Org-mode files will be re-evaluated and re-exported to GFM files.

If you want to scaffold a new project with these scripts, you can create a new directory, go into it, and invoke the following `nix` call:

```shell
nix run \
    --file http://github.com/shajra/nix-project/tarball/master \
    nix-project-exe \
    --ignore-environment \
    --command nix-project --scaffold --nix `command -v nix`
```

Note that we're using `nix run` again, similarly to how we configured shajra.cachix.org before. Even `support/dependencies-upgrade` and `support/docs-generate` are essentially calls to `nix run`. [The provided documentation on Nix](doc/nix.md) has a section explaining more of how `nix run` works.

In the freshly scaffolded project, you'll see the following files:

    ├── nix
    │   ├── default.nix
    │   ├── sources.json
    │   └── sources.nix
    ├── README.org
    └── support
        ├── dependencies-upgrade
        └── docs-generate

`nix/sources.json` and `nix/sources.nix` are overwritten by calls to Niv (via `nix-project` via `dependencies-upgrade`), but the rest of the files are yours to modify as you see fit.

## Managing dependencies<a id="sec-2-4"></a>

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
    
        If multiple commands are specified, the last one is used.
        Similarly, if a switch is specified multiple times, the last
        one is used.
    
    COMMANDS:
    
        -s, --scaffold  set up current directory with example scripts
        -u, --upgrade   upgrade dependencies with Niv
        -n, --niv       pass arguments directly to Niv
    
        Note '--upgrade' runs the following in one step:
    
    	niv init; niv update
    
    OPTIONS:
    
        -h --help            print this help message
        -t --target-dir DIR  directory of project to manage
    			  (default: current directory)
        -S --source-dir DIR  directory relative to target for
    			  Nix files (default: nix)
        -g --github-token    file with GitHub API token (default:
    			  ~/.config/nix-project/github.token)
        -N --nix PATH        filepath of 'nix' executable to use
    
        'nix-project' pins all dependencies except for Nix itself,
         which it finds on the path if possible.  Otherwise set
         '--nix'.

Since `nix-project` can pass through commands to `niv` we can see the help for Niv with the following command:

```shell
support/dependencies-upgrade --niv -- --help
```

    niv - dependency manager for Nix projects
    
    version: 0.2.13
    
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

## Evaluating/exporting documentation<a id="sec-2-5"></a>

A freshly scaffolded project will have a `README.org` file in its root. This file has an example call to `whoami` in it. When you call `support/docs-generate`, you'll see that the `README.org` file is modified in place to include the result of the `whoami` call. Additionally, a `README.md` file is exported.

Notice that the `support/docs-generate` script includes the `pkgs.coreutils` package. This is the package that provides the `whoami` executable. You explicitly control what executables are in scope for evaluating your code snippets. `pkgs` provides all the packages that come with the [Nixpkgs repository](https://github.com/NixOS/nixpkgs), but you can always define your own packages with a Nix expression.

> **<span class="underline">NOTE</span>**: Since `docs-generate` writes over files in-place, source control is highly recommended to protect against the loss of documentation.

The `org2gfm` script that `docs-generate` delegates to does not support all Emacs Org-mode evaluation/export features. See [doc/org2gfm-design](doc/org2gfm-design.md) for a discussion of `org2gfm`'s design and recommended usage.

For reference, here's the documentation from the `--help` switch for `docs-generate` / `org2gfm`:

```shell
support/docs-generate --help
```

    USAGE: org2gfm [OPTION]...  [FILE]...
    
    DESCRIPTION:
    
        Uses Emacs to export Org-mode files to GitHub Flavored
        Markdown, which are written to sibling ".md" files.  If no
        files are specified, then all '*.org' files found recursively
        from the current working directory are used instead.
    
    OPTIONS:
    
        -h --help          print this help message
        -e --evaluate      evaluate all SRC blocks before exporting
        -E --no-evaluate   don't evaluate before exporting (default)
        -N --nix PATH      filepath to 'nix' binary to put on PATH
        -i --ignore REGEX  ignore matched paths when searching
        -y --yes           answer "yes" to all queries for evaluation
        -n --no            answer "no" to all queries for evaluation
    
        This script is recommended for use in a clean environment
        with a PATH controlled by Nix.  This helps make executed
        source blocks more deterministic.  However, if the source
        blocks need to execute Nix commands, it's best to use the Nix
        version already installed on the system, rather than a pinned
        version.  This is what the '-N' option is for.
    
        If using both '-e' and '-E' options the last one is overriding
        (useful for automation/defaults).
    
        Note, the '-e' switch evaluates the Org-mode file in-place.
        No evaluation occurs during the export to Markdown, which
        will have the same blocks as the Org-mode file.

## GitHub rate limiting of Niv calls<a id="sec-2-6"></a>

Many dependencies managed by Niv may come from GitHub. GitHub will rate limit anonymous API calls to 60/hour, which is not a lot. To increase this limit, you can make a [personal access token](https://github.com/settings/tokens) with GitHub. Then write the generated token value in the file `~/.config/nix-project/github.token`. Make sure to restrict the permissions of this file appropriately.

## Next steps<a id="sec-2-7"></a>

At this point, you can create a skeleton project with dependencies and generate documentation for it. But you need to know more about Nix and the Nix expression language to build your own projects with Nix.

the `nix/default.nix` in the skeleton project derives packages from `sources.json`. You can make more Nix expressions in this directory and reference them in `nix/default.nix`.

If you haven't looked it yet, in the [./doc](./doc) directory, this project provides

-   [some documentation on Nix](doc/nix.md) to get you started
-   [design and recommended usage of `org2gfm`](doc/org2gfm-design.md).

Finally, the [official Nix documentation](https://nixos.org/learn.html) is comprehensive, and can help you make your own Nix expressions using the Nixpkgs repository as a foundation. Particularly useful are the [Nix manual](https://nixos.org/nix/manual) and [Nixpkgs manual](https://nixos.org/nixpkgs/manual).

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
