- [About this document](#sec-1)
- [Prerequisites](#sec-2)
- [Scaffolding](#sec-3)
  - [Scaffolding a new project](#sec-3-1)
  - [Development features of scaffolded projects](#sec-3-2)
  - [Additional caching of Nix evaluations](#sec-3-3)
- [Authoring flakes](#sec-4)
  - [Overview of `flake.nix`](#sec-4-1)
  - [System-specific flake outputs](#sec-4-2)
  - [Recommended Nix build pattern](#sec-4-3)
  - [Defining overlays](#sec-4-4)
  - [Using `callPackage`](#sec-4-5)
- [Updating dependencies](#sec-5)
- [Next Steps](#sec-6)


# About this document<a id="sec-1"></a>

This document shows how to get started managing a software project using the following in conjunction:

-   the [Nix package manager](https://nixos.org/nix)
-   an experimental feature of Nix called [flakes](https://nixos.wiki/wiki/Flakes)
-   this project, Nix-project.

This document focuses on basics, without the added abstraction complexity of third-party support like [`flake-utils`](https://github.com/numtide/flake-utils) or [`flake-parts`](https://github.com/hercules-ci/flake-parts). A [separate document](project-developing-modules.md) covers development with flakes modules (using `flake-parts`).

> **<span class="underline">NOTE:</span>** To understand more about why to use an experimental feature such as flakes, as well as known trade-offs, please read the provided [supplemental documentation on Nix](nix-introduction.md).

# Prerequisites<a id="sec-2"></a>

If you're new to Nix, consider reading the provided [introduction](nix-introduction.md).

If you don't have Nix set up yet, see the provided [installation and configuration guide](nix-installation.md). You will need Nix's experimental flakes feature enabled to continue following this development guide. Otherwise, you'll need to pass `--extra-experimental-features 'nix-command flakes'` explicitly to call invocations of the `nix` command.

If you don't know how to use basic Nix commands, see the provided [usage guide](nix-usage-flakes.md).

If you're new to the Nix programming language, see the provided [language tutorial](nix-language.md).

# Scaffolding<a id="sec-3"></a>

Nix-project provides two templates you can use to scaffold a new project:

-   `less`: uses Nix flakes directly without projects like [flake-utils](https://github.com/numtide/flake-utils) or [flake-parts](https://github.com/hercules-ci/flake-parts)
-   `more`: uses flakes with more third-party support like [flake-parts](https://github.com/hercules-ci/flake-parts).

Though implemented differently, both `less` and `more` templates have feature parity. That way, you can more easily see how to extend your own project in two different styles.

Adoption of `flake-parts` by the community has been partial. Some appreciate the community-curated module ecosystem it enables. Others dislike the additional abstraction complexity. Note, there's little reason to use `flake-utils` given we can get the same benefit with under ten lines of Nix code as illustrated in the `less` template.

Regardless of whether you use `flake-parts` or not, it's good to understand how to use Nix flakes directly. The rest of this document focuses on the `less` template. A [companion document](project-developing-modules.md) walks through the `more` template.

## Scaffolding a new project<a id="sec-3-1"></a>

We can scaffold a project with the `less` template with the following command:

```sh
nix --refresh \
    flake new \
    --template github:shajra/nix-project/main#less \
    /tmp/my-project-less  # or wherever you want your new project
```

    wrote: "/tmp/my-project-less/README.org"
    wrote: "/tmp/my-project-less/config.nix"
    wrote: "/tmp/my-project-less/flake.nix"
    wrote: "/tmp/my-project-less/nix/my-app.nix"
    wrote: "/tmp/my-project-less/nix/overlay.nix"
    wrote: "/tmp/my-project-less/nix"

The `--refresh` assures that you get the latest template rather than a cached version from a previous invocation.

As is common for all flake-based projects, [`flake.nix`](../examples/less/flake.nix) is the top-level build file. As an ergonomic choice, [`config.nix`](../examples/less/config.nix) factors out declarative build parameters. [`nix/overlay.nix`](../examples/less/nix/overlay.nix) illustrates a common and recommended pattern for managing multi-package builds where packages can depend on both third-party dependencies as well as one another. [`nix/my-app.nix`](../examples/less/nix/my-app.nix) illustrates packaging a simple shell script with Nix.

## Development features of scaffolded projects<a id="sec-3-2"></a>

To start, from the root of a scaffolded project you can enter a developer environment and see some available preconfigured commands:

```sh
nix develop
```

    
    [[general commands]]
    
      menu            - prints this menu
      project-check   - run all checks/tests/linters
      project-doc-gen - generate GitHub Markdown from Org files
      project-format  - format all files in one command

`project-doc-gen` generates documentation tailored for repositories hosted on GitHub. It uses the `org2gfm` script/library provided by Nix-project and is discussed in [another document](project-documenting.md).

Run `project-format` (no arguments needed) to format in-place all source code using [treefmt-nix](https://github.com/numtide/treefmt-nix).

`project-check` is an alias for `nix flake check` to run all checks/tests/lints with a simple command.

As with all Nix flake-based projects, all normal `nix` commands apply, as documented in [the included guide on using Nix flakes](./nix-usage-flakes.md). For example, you can run the example program provided by the template with `nix run` (which just curls the Nix website):

```sh
nix run
```

    Nixos Logo
    Explore Download Learn Governance Community Blog Donate Search
    NixOS 25.11 released Read Announcement
    
    Declarative builds
    and deployments.
    
    Nix is a tool that takes a unique approach to package management and system
    configuration. Learn how to make reproducible, declarative and reliable
    …

## Additional caching of Nix evaluations<a id="sec-3-3"></a>

Evaluating Nix expressions can be slow, even with the improvements of Nix flakes. For example, this cost can be felt when running `nix fmt` to run the configured formatter on all source code of the project. Instead, many developers enter a developer environment with `nix develop`, paying the cost of evaluating the Nix expression upon entry, and then running the formatter directly with a command like `project-format` or `treefmt`.

By installing and configuring both [`direnv`](https://direnv.net) and [`nix-direnv`](https://github.com/nix-community/nix-direnv) you can cache Nix evaluations even more aggressively, only rebuilding the environment when dependencies provided by the flake actually change. Note `direnv` comes with built-in support for flakes, and `nix-direnv` improves the caching of this built-in support.

Covering `direnv` and `nix-direnv` in detail is beyond the scope of this document, but the steps to get started should look like:

1.  Install `direnv`
2.  Install `nix-direnv`
3.  At the root of your project:
    1.  `echo 'use flake' > .envrc`
    2.  `direnv allow` (a security gate of `direnv`)

Then when you enter the directory of your project for the first time, a shell prompt hook will evaluate your flake, cache the result, and seamlessly set up environment variables (including the `PATH`) as per the environment provided by `nix develop`.

Popular editors even have plugins/extensions for `direnv` support, for example

-   [`direnv`'s official VSCode plugin](https://github.com/direnv/direnv-vscode)
-   [`direnv`'s official Vim plugin](https://github.com/direnv/direnv.vim)
-   [a popular `direnv` Emacs package](https://github.com/purcell/envrc)

With these plugins, when you open a file within a project with an enabled `.envrc` configuration for `direnv`, your editor will automatically enter the environment to find tools on the `PATH` and other environment variables.

# Authoring flakes<a id="sec-4"></a>

The Nix community generally enjoys the freedom of configuration with a programming language as expressive as Nix. The code in the templates may be clean enough that you can intuit what's going on after [learning the Nix language](./nix-language.md). However, even the small templates provided synthesize a number of standards, conventions, and recommended patterns that may seem unfamiliar. This is a trade-off for having a rich programming language like Nix as a configuration language, rather than a grammar as constrained as YAML, TOML, or JSON.

This section aims to explain the requisite Nix expressions well enough that you can extend the provided templates to whatever you desire.

## Overview of `flake.nix`<a id="sec-4-1"></a>

A good way to start understanding a flakes-based project is to read the `flake.nix` file at the project's root.

Every `flake.nix` file must conform to a standard structure of an attribute set with three attributes, `description`, `inputs`, and `outputs`. Here are some highlights from the `flake.nix` of `less` template:

```nix
{
  description = "Example project with less third-party dependencies";

  inputs = {
    devshell.url = "github:numtide/devshell";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-project.url = "github:shajra/nix-project";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      self,
      devshell,
      nixpkgs,
      ...
    }:
        # …
    ;
}
```

The `description` is just a simple textual string.

`inputs` specifies all the dependencies needed by our project. Many of these dependencies could well be flakes themselves. Others might be pointers to online files. Most of these inputs are specified in a URI syntax. See the [official documentation on flake references](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-references) for more details.

The `less` template has four dependencies:

-   `nix-project` (this project), for document generation
-   [`nixpkgs`](https://github.com/NixOS/nixpkgs), a central library for Nix almost all packages build off of
-   [`devshell`](https://github.com/numtide/devshell), to enhance the `nix develop` experience
-   [`treefmt-nix`](https://github.com/numtide/treefmt-nix), for formatting source code conveniently.

The `outputs` attribute is where we specify what our flake provides. We define it as a function. The head of this function is an attribute set mapping input names to their respective outputs (we also get a special `self` input for the flake we're in the process of defining). The function's body returns an attribute set of everything our flake provides as outputs.

Note that what is specified in `inputs` describes how to get our dependencies, but this is different from the inputs supplied to the `outputs` function, which are the dependencies themselves.

Nix does not strictly enforce the schema of the outputs returned by `outputs` function. However, some attributes are special with respect to defaults searched by various `nix` subcommands. You can run `nix flake check` to see that your flake passes basic checks, including warnings for any outputs not recognized as standard.

The official Nix documentation doesn't yet have a specification of all standard outputs in one place. The Nix wiki, though, has a [useful section on outputs](https://nixos.wiki/wiki/Flakes#Output_schema).

The output attributes produced by the templates include

-   `packages`, referenced by `nix build` and `nix run`
-   `apps`, referenced by `nix run`
-   `devshells`, referenced by `nix develop`
-   `formatters`, referenced by `nix fmt`
-   `checks`, referenced by `nix flake check`

## System-specific flake outputs<a id="sec-4-2"></a>

Flakes, by design, disallow the build platform from being queried, even to see which chipset we will be building on. This restriction ensures some portability and reproducibility, but introduces some complexity when defining and accessing flake outputs. For every package, a flake must provide a different output for each system supported.

Flake outputs exposing packages end up with attribute paths like

-   `packages.<system>.<name>` (how most flakes output packages)
-   `legacyPackages.<system>.<attribute path>` (how [Nixpkgs](https://github.com/NixOS/nixpkgs) outputs packages)

You can see all the systems used by Nix with the following command:

```sh
nix eval nixpkgs#lib.platforms.all
```

The complication means we have to write Nix expressions that build packages for every system we want to support. To assist, the `less` template `flake.nix` file provides two functions, `buildFor` and `forAllSystems`.

Discussed in [another document](project-developing-modules.md), `flake-parts`, used by the `more` template, provides a different abstraction to solve the same problem.

## Recommended Nix build pattern<a id="sec-4-3"></a>

Many (though not all) of a flakes outputs are special Nix expressions that specify a Nix package. Building packages from scratch is generally impractical, which is why we almost always use the support of Nixpkgs as a base dependency.

Nixpkgs is an extremely deep and wide nested attribute set, containing well over 120,000 packages and various functions to help build more.

We can then craft special functions, called *overlays* that take one version of Nixpkgs, and overlays on top of it more packages and functions to make a new version.

In code this can look like:

```nix
let
  overlay = import path/to/my/overlay.nix {};  # or whatever args required
  new_nixpkgs = (import prev_nixpkgs) {
    inherit system;  # get system already in scope
    overlays = [ overlay ];
  }
in ⋯
```

Or if you only have one overlay, you may simply see:

```nix
let
  overlay = import path/to/my/overlay.nix {};  # or whatever args required
  new_nixpkgs = prev_nixpkgs.extend overlay;
in ⋯
```

Overlays typically make heavy usage of a function provided by Nixpkgs called `callPackage` to create new packages from preexisting ones. Both overlays and `callPackage` are discussed in greater detail in later sections.

So a *build* in the context of our project is ultimately, a Nixpkgs instance that has all the packages and functions we want to expose through outputs of our flake.

## Defining overlays<a id="sec-4-4"></a>

Both the `less` and `more` templates illustrate the use of overlays, which are defined in their respective `nix/overlay.nix` files, and used in their respective `flake.nix` files.

An overlay has the following form:

```nix
final: prev: {
    # new attributes to be merged into Nixpkgs
}
```

We start with an instance of Nixpkgs, and can chain overlays:

```nix
(nixpkgs.extend overlay1).extend overlay2
```

The `prev` parameter of the overlay allows us to access the version of Nixpkgs the overlay is directly extending. The `final` parameter enables us to access the version of Nixpkgs we'll get when all overlays have been applied.

For those familiar, `final` is the kind of open recursion we get with the `self` or `this` parameter in object-oriented (OO) languages. Similarly `prev` is like `super`. Similar to OO languages, we can use overlays to override packages referenced from `final` in any other overlay. References from `prev` can only be overridden by previous overlays. Overriding is powerful because we can override *all* references to a dependency. Overriding all references helps keep everything in our Nixpkgs instance on the same version for consistency and compatibility.

A typical pattern is to start with Nixpkgs, and extend it with more packages via overlays, until we finally have packages we want to distribute.

Here is the `less` template's overlay:

```nix
inputs: final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
  config = final.callPackage ../config.nix { };
in
{
  my-app = final.callPackage ./my-app.nix { };

  my-app-mkShell = prev.mkShell config.mkShell;
  my-app-devshell = final.devshell.mkShell { imports = [ config.devshell ]; };
  my-app-org2gfm = inputs.nix-project.lib.${system}.org2gfm-static config.org2gfm;
  my-app-treefmt = inputs.treefmt-nix.lib.evalModule final config.treefmt;
}
```

This generator of an overlay takes the flake's `inputs` as an argument. This way, we can build new packages not only from what's in Nixpkgs, but anything we've pulled in as flake inputs. Within our overlay, we assume that Nixpkgs has already been specialized to a specific platform, which we can get from `prev.stdenv.hostPlatform.system`.

Additionally, the overlay defines a small application using the `callPackage` function from Nixpkgs. This is discussed in the next section.

Worth noting, another overlay can override anything in Nixpkgs or provided by a previous overlay. If building a package involves building some intermediate artifacts, you might want to expose those artifacts by including them in an overlay distributed in your flake's `overlays` output. Distributing overlays enables others to use the overlay and override these intermediate artifacts to get a different build.

## Using `callPackage`<a id="sec-4-5"></a>

Both `less` and `more` templates provide the same definition of an application in `nix/my-app.nix`, which has been written in a common Nix style:

```nix
{
  writeShellApplication,
  curl,
  w3m,
}:

writeShellApplication {
  name = "my-app";
  meta.description = "Example application";
  runtimeInputs = [
    curl
    w3m
  ];
  text = ''
    curl -s 'https://nixos.org' | w3m -dump -T text/html
  '';
}
```

The attribute set input of this function expects dependencies passed in and returns the derivation of a package. All these dependencies happen to exist in a default instance of Nixpkgs:

-   `writeShellApplication` is a Nixpkgs utility to make a package providing a simple shell script.
-   `curl` is the standard cURL program that can download HTTP content.
-   `w3m` is a text-based web browser.

We could pass in these dependencies explicitly, but if there are many dependencies this can get tedious. Nixpkgs comes with a utility function `callPackage` that will

-   inspect (using reflection) the attribute names of the set input of a function
-   call the function passing in values retrieved from Nixpkgs with these names.

Some people recognize this kind of utility as *dependency injection*. The `callPackage` utility accepts two arguments:

1.  the function (or path to a Nix file evaluating to it) with dependencies to be injected
2.  an attribute set to overlay on top of Nixpkgs when looking up dependencies.

Using `final.callPackage`, various packages that depend on one another can be defined in the same overlay. Here's an example:

```nix
final: prev: {
    my-app-a = final.callPackage ({writeShellApplication}: …) {};
    my-app-b = final.callPackage ({writeShellApplication, my-app-a}: …) {};
    my-app-c = final.callPackage ({writeShellApplication, my-app-a, my-app-b}: …) {};
}
```

Here `my-app-a` is a simple shell script that doesn't rely on anything more than shell. `my-app-b` is a script that uses `my-app-a`. And `my-app-c` is a script that uses both `my-app-a` and `my-app-b`. Notice that for these second two `callPackage` calls, we can not use `prev.callPackage`, because dependencies required wouldn't exist until this overlay was applied to Nixpkgs.

Note the final argument of `callPackage` (we're always passing in an empty `{}`) is an opportunity to pass in any dependencies not found in the Nixpkgs instance. However, if you use overlays and `final` effectively, you can easily find yourself not needing any more than an empty `{}`.

Though new packages are often defined using `callPackage`, this is not always the case. For example, in the `less` template `my-app-org2gfm` and `my-app-treefmt` are built from custom functions (not `callPackage`) provided by input flakes. `my-app-devshell` is built from a function made available by a previously applied overlay. And `my-app-mkShell` is built from a standard function provided by Nixpkgs.

Each project will provide its own way of building packages for your flake, but all should fit neatly into the framework of overlays, as illustrated by the templates.

# Updating dependencies<a id="sec-5"></a>

You'll notice the first time you run a `nix` command against your newly scaffolded project, a `flake.lock` lock file will be generated. Flake inputs can point to mutable references like Git repository branches. The lock file pins references to a specific snapshot retrieved.

This lock file should be checked in with your source. This file is what makes your build repeatable.

When we want to update all the dependencies in our lock file, we can run:

```sh
nix flake update
```

# Next Steps<a id="sec-6"></a>

This guide and scaffolded projects used as an examples, show how to make packages providing a simple shell script. You will likely want to start making packages for other languages.

Nix has an [official learning starting point](https://nixos.org/learn.html), that is a good next step. In particular, you will find yourself reading the [Nixpkgs manual](https://nixos.org/nixpkgs/manual).

The guides included in this project cover more of the language-agnostic aspects of Nix and Nixpkgs. Each programming language ecosystem has its set of unique requirements and idiosyncrasies. Nixpkgs provide functions to assist with each language, which can lead to some divergent experiences when packaging and developing with Nix. The Nixpkgs manual has [dedicated sections for each language](https://nixos.org/manual/nixpkgs/stable/#chap-language-support). Eventually, you will find yourself diving into [Nixpkgs source code](https://github.com/NixOS/nixpkgs).

The Nix ecosystem is vast. This project and documentation illustrate just a small sample of what Nix can do.
