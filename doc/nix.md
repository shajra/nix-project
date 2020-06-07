- [How this project uses Nix](#sec-1)
- [Motivation to use Nix](#sec-2)
- [Installation and Setup](#sec-3)
  - [Nix package manager setup](#sec-3-1)
  - [Cache setup](#sec-3-2)
- [Working with Nix](#sec-4)
  - [Understanding Nix files](#sec-4-1)
  - [Building Nix expressions](#sec-4-2)
  - [Running commands](#sec-4-3)
  - [Garbage collection](#sec-4-4)
- [Next Steps](#sec-5)


# How this project uses Nix<a id="sec-1"></a>

This project uses the [Nix package manager](https://nixos.org/nix) to download all necessary dependencies and build everything from source.

Because Nix is more than a build system, notably a full package manager, the final build is actually a Nix package that you can install with the Nix package manager if you like.

Builds from this project are cached at [Cachix](https://cachix.org), a service that caches pre-built Nix packages. If you don't want to wait for a full local build, setting up Cachix is recommended.

The various files with a ".nix" extension are Nix files, each of which contains an expression written in the [Nix expression language](https://nixos.org/nix/manual/#ch-expression-language) used by the Nix package manager. If you get proficient with this language, you can compose expressions together to make your own packages from others (if that's useful to you).

# Motivation to use Nix<a id="sec-2"></a>

When making a new software project, wrangling dependencies can be a chore. For instance, GNU Make's makefiles often depend on executables and libraries that may or may not be on a system. The makefiles in most projects don't assist with getting these dependencies at usable versions. And many projects just provide error-prone instructions for how to get and install these dependencies manually.

Nix can build and install projects in a way that's precise, repeatable, and guaranteed not to conflict with anything already installed. Nix can even concurrently provide multiple versions of any package without conflicts.

Furthermore, Nix supports building source of a variety of languages. In many cases, Nix picks up where language-specific tooling stop, layering on top of the tools and techniques native to those ecosystems. Nix expressions are designed for composition, which helps integrate packages from dependencies that may not all come from the same language ecosystem. These dependencies in Nix are themselves Nix packages.

To underscore how repeatable and precise Nix builds are, it helps to know that Nix uniquely identifies packages by a hash derived from the hashes of requisite dependencies and configuration. This is a recursive hash calculation that assures that the smallest change to even a distant transitive dependency changes the hash. When dependencies are downloaded, they are checked against the expected hash. Most Nix projects (this one included) are careful to pin dependencies to specific versions/hashes. Because of this, when building the same project with Nix on two different systems, we get an extremely high confidence we will get the same output, often bit-for-bit. This is a profound degree of precision relative to other popular package managers.

The repeatability and precision of Nix enables caching services, which for Nix are called *substituters*. Cachix is one such substituter. Before building a package, the hash for the package is calculated. If any configured substituter has a build for the hash, it's pulled down as a substitute. A certificate-based protocol is used to establish trust of substituters. Between this protocol, and the algorithm for calculating hashes in Nix, you can have confidence that a package pulled from a substituter will be identical to what you would have built locally.

All of this makes Nix an attractive tool for managing almost any software project.

# Installation and Setup<a id="sec-3"></a>

## Nix package manager setup<a id="sec-3-1"></a>

> **<span class="underline">NOTE:</span>** You don't need this step if you're running NixOS, which comes with Nix baked in.

If you don't already have Nix, the official installation script should work on a variety of GNU/Linux distributions, and also Mac OS. The easiest way to run this installation script is to execute the following shell command as a user other than root:

```shell
curl https://nixos.org/nix/install | sh
```

This script will download a distribution-independent binary tarball containing Nix and its dependencies, and unpack it in `/nix`.

If you prefer to install Nix another way, reference the [Nix manual](https://nixos.org/nix/manual/#chap-installation)

## Cache setup<a id="sec-3-2"></a>

It's recommended to configure Nix to use shajra.cachix.org as a *Nix substituter*. This project pushes built Nix packages to [Cachix](https://cachix.org) as part of its continuous integration. Once configured, Nix will pull down these pre-built packages instead of building them locally.

You can configure shajra.cachix.org as a substituter with the following command:

```shell
nix run \
    --file https://cachix.org/api/v1/install \
    cachix \
    --command cachix use shajra
```

This will perform user-local configuration of Nix at `~/.config/nix/nix.conf`. This configuration will be available immediately, and any subsequent invocation of Nix commands will take advantage of the Cachix cache.

If you're running NixOS, you can configure Cachix globally by running the above command as a root user. The command will then configure `/etc/nixos/cachix/shajra.nix`, and the output will explain how to tie this configuration into your normal NixOS configuration.

# Working with Nix<a id="sec-4"></a>

Though covering Nix comprehensively is beyond the scope of this document, we'll go over a few commands illustrating using Nix with this project.

## Understanding Nix files<a id="sec-4-1"></a>

Each of the Nix files in this project (ones with a ".nix" extension) contains exactly one Nix expression. This expression evaluates to one of the following values:

-   simple primitives and functions
-   derivations of packages that can be built and installed with Nix
-   containers of values, allowing a single value to provide more than one thing (these containers can nest).

Once you learn the Nix language, you can read these files to see what kind of values they build. We can use the `nix search` command to see what package derivations a Nix expression contains. For example from the top-level of this project, we can execute:

```shell
nix search --file default.nix --no-cache
```

    * nix-project-exe (nix-project)
      Script to scaffold and maintain dependencies for a Nix project
    
    * nix-project-org2gfm (org2gfm)
      Script to export Org-mode files to GitHub Flavored Markdown (GFM)

Note that because for extremely large Nix expressions, searching can be slow, `nix search` by defaults uses a indexed cache. This cache can be explicitly updated. However, because local projects rarely have that many package derivations, the `--no-cache` switch is used and recommended to bypass the cache for these projects. This guarantees accurate results that are fast enough.

The output of `nix search` is formatted as

    * attribute-name (name-of-package)
      Short description of package

The *attribute names* are used to select values from a Nix set containing multiple package derivations. If the Nix expression evaluates to a single derivation, the attribute name will be missing from the `nix search` result.

Many Nix commands evaluate Nix files. If you specify a directory instead, the command will look for a `default.nix` file within to evaluate. So from the top-level of this project, we could use `.` instead of `default.nix`:

```shell
nix search --file . --no-cache
```

In the remainder of this document, we'll use `.` instead of `default.nix` since this is conventional for Nix.

## Building Nix expressions<a id="sec-4-2"></a>

From our execution of `nix search` we can see that a package named "nix-project" can be accessed with the "nix-project-exe" attribute name in the Nix expression in the top-level `default.nix`.

We can build this package with `nix build` from the top-level:

```shell
nix build --file . nix-project-exe
```

Because `nix build` by default builds `default.nix`, you don't need the `--file .` argument. So our invocation could be even more simple:

```shell
nix build nix-project-exe
```

The positional arguments to `nix build` are attribute names. If you supply none then all attributes are built by default.

All packages built by Nix are stored in `/nix/store`. Nix won't rebuild packages found there. Once a package is built, its directory in `/nix/store` is read-only (until the package is deleted).

After a successful call of `nix build`, you'll see some symlinks for each package requested in the current working directory. These symlinks by default have a name prefixed with "result" and point back to the respective build in `/nix/store`:

```shell
readlink result*
```

    /nix/store/zhc6wmz51l2vzv56xr3p957vc5cbzqlc-nix-project

Following these symlinks, we can see the files the project provides:

```shell
tree -l result*
```

    result
    └── bin
        └── nix-project
    
    1 directory, 1 file

It's common to configure these "result" symlinks as ignored in source control tools (for instance, within a Git `.gitignore` file).

## Running commands<a id="sec-4-3"></a>

You can run a command from a package in a Nix expression with `nix run`.

For instance, to get the help message for the `nix-project` executable with `nix run` we'd call the following:

```shell
nix run \
    --file . \
    nix-project-exe \
    --command nix-project --help
```

    USAGE:
    
        nix-project [OPTION]... --scaffold
        nix-project [OPTION]... --upgrade
        nix-project [OPTION]... --niv -- COMMAND...
    …

Note that unlike `nix build` the `--file .` argument is needed in this case. The default expression for `nix run` is different than `default.nix` in the current working directory.

Again, as with `nix build` attribute names are specified as position argument to select packages. And a command is specified after the `--command` switch. `nix run` runs the command in a shell set up with a `PATH` environment variable including all the `bin` directories provided by the selected packages

You don't even have to build the package first with `nix build` or mess around with the "result" symlinks. `nix run` will build the project if it's not yet been built.

## Garbage collection<a id="sec-4-4"></a>

Old versions of packages stick around in `/nix/store`. We can clean this up with garbage collection by calling `nix-collect-garbage`.

For each package, Nix is aware of all references back to `/nix/store` for other packages, whether in text files or binaries. This allows Nix to prevent the deletion of a runtime dependency required by another package.

Symlinks pointing to packages to exclude from garbage collection are maintained by Nix in `/nix/var/nix/gcroots`. Looking closer, you'll see that for each `nix build` invocation, there's symlinks in `/nix/var/nix/gcroots/auto` pointing back to each "result" symlinks created, which in turn points to respective packages in `/nix/store`. These symlinks prevent packages built by `nix build` from being garbage collected. If you want a package you've built with `nix build` to be garbage collected, delete the "result" symlink created before calling `nix-collect-garbage`. `nix-collect-garbage` will clean up broken symlinks in `/nix/var/nix/gcroots/auto`.

Also, it's good to know that `nix-collect-garbage` won't delete packages referenced by any running processes. In the case of `nix run` no garbage collection root symlink is created under `/nix/var/nix/gcroots`, but while `nix run` is running a `nix-collect-garbage` won't delete packages needed by the invocation. However, once the `nix run` call exits, any packages pulled from a substituter or built locally are candidates for deletion by `nix-collect-garbage`. If you called `nix run` again after garbage collecting, those packages might be pulled or built again.

# Next Steps<a id="sec-5"></a>

This document has covered a fraction of Nix usage, hopefully enough to introduce Nix in the context of [this project](../README.md).

An obvious place to start learn more about Nix is [the official documentation](https://nixos.org/learn.html). The author of this project also maintains [a small tutorial on Nix](https://github.com/shajra/example-nix/tree/master/tutorials/0-nix-intro).

You may benefit from learning more about `nix-env`, which some people use to maintain symlinks pointing back to packages in `/nix/store`. This way, you only have to add `~/.nix-profile/bin` to your `PATH`, rather than the `bin` directory for every package you want to use.

We also didn't cover `nix-shell`, which can be used for setting up development environments.

And we didn't cover [Nixpkgs](https://github.com/NixOS/nixpkgs), a gigantic repository of community-curated Nix expressions.

The Nix ecosystem is vast. This project illustrates just a small example of what Nix can do.
