- [About this document](#sec-1)
- [Prerequisites](#sec-2)
- [Scaffolding](#sec-3)
- [Authoring flakes](#sec-4)
  - [Overview of `flake.nix`](#sec-4-1)
  - [System-specific flake outputs](#sec-4-2)
  - [Authoring flake outputs with `flake-parts`](#sec-4-3)
  - [Overlays](#sec-4-4)
  - [Making applications with `callPackage`](#sec-4-5)
- [Updating dependencies](#sec-5)
- [Next Steps](#sec-6)


# About this document<a id="sec-1"></a>

This document shows how to get started managing a software project using the following in conjunction:

-   the [Nix package manager](https://nixos.org/nix)
-   an experimental feature of Nix called [flakes](https://nixos.wiki/wiki/Flakes)
-   this project, Nix-project.

Nix-project provides library support that helps ease the ergonomics of using Nix with flakes.

> **<span class="underline">NOTE:</span>** To understand more about why to use an experimental feature such as flakes, as well as known trade-offs, please read the provided [supplemental documentation on Nix](nix-introduction.md).

Nix-project uses all the features it provides itself, so you can look through this repository for concrete examples of how to do what's discussed in this document.

# Prerequisites<a id="sec-2"></a>

If you're new to Nix consider reading the provided [introduction](nix-introduction.md).

If you don't have Nix set up yet, see the provided [installation and configuration guide](nix-installation.md). You will need Nix's experimental flakes feature enabled to continue following this development guide.

If you don't know how to use basic Nix commands, see the provided [usage guide](nix-usage-flakes.md).

If you're new to the Nix programming language, see the provided [language tutorial](nix-language.md).

# Scaffolding<a id="sec-3"></a>

Nix-project provides a template you can use to scaffold a new project. This scaffold captures recommended conventions also used by Nix-project itself.

If you want to scaffold a new project set up similarly, you can go into a writable directory and invoke the following `nix` call:

```sh
nix --extra-experimental-features nix-command \
    --refresh run github:shajra/nix-project/main#nix-scaffold \
    -- --target-dir /tmp/my-project  # or whereever you like
```

    SUCCESS: Scaffolded Nix project at /tmp/my-project

The `--refresh` assures that you get the latest version of the scaffolding script from the internet if you've made this `nix run` invocation before.

In the freshly scaffolded project, you'll see the following files:

    my-project
    ├── default.nix
    ├── flake.nix
    ├── nix
    │   ├── compat.nix
    │   ├── my-app.nix
    │   └── overlay.nix
    ├── README.org
    └── support
        └── docs-generate

`README.org` and `support/docs-generate` are used to document your project and are discussed in [another document](project-documenting.md).

`default.nix` and `nix/compat.nix` provide non-flakes support for users of your project who have decided not to enable flakes in their Nix installation. These are static files that you shouldn't typically have to modify. They expose the flake defined in `flake.nix` as a Nix expression of packages. The provided [guide on using Nix without flakes](nix-usage-noflakes.md) illustrates how end users without flakes can use the `default.nix` and `nix/compat.nix` files in the scaffolded project. The [guide on using Nix with flakes](nix-usage-flakes.md) will match other user's experience.

You'll modify the top-level `flake.nix` file and the Nix files under the `nix` directory (with exception of `compat.nix`) to customize the scaffolded project to your needs.

# Authoring flakes<a id="sec-4"></a>

As documented in the provided [introduction to Nix](nix-introduction.md), we're using the experimental flakes feature of Nix for a few reasons:

-   more assurances of a deterministic and reproducible build
-   faster evaluation from improved caching
-   an improved ergonomic experience for authors of Nix projects
-   an improved ergonomic experience for end users consuming Nix projects

## Overview of `flake.nix`<a id="sec-4-1"></a>

The best way to start understanding a flakes-based project is to read the `flake.nix` file at the project's root. This file is written in the Nix programming language. See the provided [introduction to the Nix language](nix-language.md) if you're new to the language.

Every `flake.nix` file must conform to a standard structure of an attribute set with three attributes, `description`, `inputs`, and `outputs`. Here are some highlights from the `flake.nix` of our scaffolded project:

```nix
{
    description = "A foundation to build Nix-based projects from.";
    inputs = {
        flake-compat    = { url = "github:edolstra/flake-compat"; flake = false; };
        flake-parts.url = "github:hercules-ci/flake-parts";
        nix-project.url = "github:shajra/nix-project";
        nixpkgs.url     = "github:NixOS/nixpkgs/nixos-25.05";
    };
    outputs = inputs@{ flake-parts, nix-project, ... }:
        # …
    ;
}
```

The `description` is just a simple textual string.

`inputs` specifies all the dependencies needed by our project. Many of these dependencies could well be flakes themselves. Others might be pointers to online files. Most of these inputs are specified in a URI syntax. See the [official documentation on flake references](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-references) for more details.

The scaffolded project has four dependencies:

-   [`flake-compat`](https://github.com/edolstra/flake-compat), to support users not using flakes (`nix/compat.nix`)
-   [`flake-parts`](https://github.com/hercules-ci/flake-parts), for an improved ergonomic experience when defining flake outputs.
-   `nix-project` (this project), for document generation (`support/docs-generations`)
-   [`nixpkgs`](https://github.com/NixOS/nixpkgs), a central library for Nix almost all packages build off of

The `outputs` attribute is where we specify what our flake provides. We define it as a function. The head of this function is an attribute set mapping input names to their respective outputs. The function's body returns an attribute set of everything our flake provides.

Note that what is specified in `inputs` describes how to get our dependencies, but this is different from the inputs supplied to the `outputs` function, which are the dependencies themselves.

Nix does not strictly enforce the schema of the outputs returned by `outputs` function. However, some attributes are special with respect to defaults searched by various `nix` subcommands. You can run `nix flake check` to see that your flake passes basic checks, including warnings for any outputs not recognized as standard.

The official Nix documentation doesn't yet have a specification of all standard outputs in one place. The Nix wiki, though, has a [useful section on outputs](https://nixos.wiki/wiki/Flakes#Output_schema).

## System-specific flake outputs<a id="sec-4-2"></a>

Flakes, by design, disallow the build platform from being queried, even to see which chipset we will be building on. This restriction ensures some portability and reproducibility, but introduces some complexity when defining and accessing flake outputs. For every package, a flake must provide a different output for each system supported.

Flake outputs end up with attribute paths like

-   `packages.<system>.<name>` (how most flakes output packages)
-   `legacyPackages.<system>.<attribute path>` (how [Nixpkgs](https://github.com/NixOS/nixpkgs) outputs packages)

You can see all the systems used by Nix with the following command:

```sh
nix eval nixpkgs#lib.platforms.all
```

## Authoring flake outputs with `flake-parts`<a id="sec-4-3"></a>

Raw flakes are an improvement over not using them, but using flakes without library assistance requires some requisite boilerplate. The scaffold pulls in [`flake-parts`](https://github.com/hercules-ci/flake-parts) reduce this boilerplate with

-   an improved DSL for defining the `outputs` attribute
-   a *flake modules* framework to allow users to extend the DSL.

Below is the fully general way of entering the `flake-parts` DSL:

You should eventually read the [official `flake-parts` documentation](https://flake.parts), but we'll cover an introduction here.

```nix
{
    # …
    outputs = inputs@{ flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } (topLevelModArgs: {
            # …
        });
}
```

Note that bindings we have in scope include our dependencies (bound to `inputs` above) and `flake-parts` top-level module arguments (bound to the `topLevelModArgs` attribute set above). These are [documented fully in the `flake-parts` documentation](https://flake.parts/module-arguments.html).

If you don't need the top-level arguments when defining your outputs, you can call `flake-parts` with a more straightforward form (though our scaffolded project uses top-level arguments):

```nix
{
    # …
    outputs = inputs@{ flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            # …
        };
}
```

As you can see from the scaffolded `flake.nix` file, `flake-parts` has us populate three attributes:

-   `systems`, a list of all the systems to build for
-   `perSystem`, a function evaluated for each system from `systems` that returns system-specific output.
-   `flake`, for outputs that pass through as raw flakes outputs

In practice, this looks something like the following:

```nix
{
    # …
    outputs = inputs@{ flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } (topLevelModArgs: {
            systems = [
                # …
            ];
            perSystem = perSystemModArgs: {
                # …
            };
            flake = {
                # …
            };
        });
}
```

In `flake-parts`, the `flake` attribute is used for flake outputs that are the same for all target systems. The `flake` component of the attribute path is dropped. For example, in our scaffolded project, `flake.overlays.build` ends up being just `overlays.build` in our project's final output.

Otherwise, all our system-specific outputs are returned by the function we set for the `perSystem` attribute. Notice the `perSystem` function has the following three bindings in scope:

-   the original flake inputs (`inputs` above)
-   top-level module arguments (`topLevelModArgs` above)
-   per-system module arguments (`perSystemModArgs` above)

The per-system module arguments are also [documented fully in the flake-parts documentation](https://flake.parts/module-arguments.html). These arguments help us avoid dealing with the system we're targeting.

For example, one of the per-system arguments is `pkgs`. If you use this argument, you are expected to have Nixpkgs bound as an input to the specially treated `nixpkgs` name.

For example, let's say we wanted to pass through GNU Hello as a package provided by our project. Without `flake-parts` we could do the following:

```nix
{
    description = "Without flake-parts";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    };
    outputs = inputs: {
        packages.x86_64-linux.my-hello  =
            inputs.nixpkgs.legacyPackages.x86_64-linux.hello;
        packages.aarch64-darwin.my-hello =
            inputs.nixpkgs.legacyPackages.aarch64-darwin.hello;
    };
}
```

This example not using `flake-parts` may not seem that bad when just passing through a package. But we end up with a lot of boilerplate if we wanted to factor out code common code for building a package. It could look as obtuse as the following:

```nix
{
    description = "Motivating flake-parts";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    };
    outputs = inputs:
        let lib = inputs.nixpkgs.lib;
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            build = system: {
                ${system}.my-hello =
                    inputs.nixpkgs.legacyPackages.${system}.hello;
            };
            packages =
                lib.foldr lib.recursiveUpdate {} (map build systems);
        in { inherit packages; };
}
```

Notice how annoying it is to deal with the `system` parameter. Here's what the same flake looks like with `flake-parts`:

```nix
{
    description = "Illustrating flake-parts";
    inputs = {
        flake-parts.url = "github:hercules-ci/flake-parts";
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    };
    outputs = inputs@{ flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            perSystem = { pkgs, ... }: {
                packages.my-hello = pkgs.hello;
            };
        };
}
```

Hopefully, the improvement in this DSL is appreciable upon inspection. We don't have to mess with a parameterization for the system. And merging everything for each system is done for us.

In the example above, rather than accessing the `hello` package from the `inputs.nixpkgs` parameter, we get it from the per-system module argument `pkgs`, which looks for `inputs.nixpkgs` by name, and selects out the appropriate `legacyPackages` for whatever system we're targeting (one of those listed in `systems`).

Additionally, in our `perSystem` we set a `packages.my-hello` attribute, and the final outputs we get in our flake are:

-   `packages.x86_64-linux.my-hello`
-   `packages.aarch64-darwin.my-hello`

See the [official flake-parts documentation](https://flake.parts/module-arguments.html) for more per-system module arguments available beyond `pkgs`. Particularly useful is `inputs'`, which can be traversed just like `inputs`, but ignoring the system component of the attribute path. So, though a little more verbose, we could use `inputs'` instead of `pkgs` as follows:

```nix
{
    description = "Illustrating flake-parts";
    inputs = {
        flake-parts.url = "github:hercules-ci/flake-parts";
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    };
    outputs = inputs@{ flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            systems = [ "x86_64-linux" "aarch64-darwin" ];
            perSystem = { inputs', ... }: {
                packages.my-hello = inputs'.nixpkgs.legacyPackages.hello;
            };
        };
}
```

## Overlays<a id="sec-4-4"></a>

The scaffolded project provides a perspective on structuring the Nix expressions to build your flake. Nixpkgs is a giant tree that is mainly made of packages. Instances of Nixpkgs can be extended with special functions called *overlays*.

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

The scaffolded project has a `nix/overlay.nix` file that defines the overlay distributed by its flake:

```nix
withSystem: final: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
in
withSystem system (
  { inputs', ... }:
  {
    nix-project-org2gfm = inputs'.nix-project.packages.org2gfm;
    my-app = final.callPackage ./my-app.nix { };
  }
)
```

This generator of an overlay takes a `withSystem` function as an argument. We get `withSystem` as a top-level module argument from `flake-parts`. `withSystem` allows access to the `inputs'` attribute set specialized to a specific platform. Within our overlay, we assume that Nixpkgs has already been specialized to a specific platform, which we can get from `prev.stdenv.hostPlatform.system`.

Additionally, the overlay defines a small application using the `callPackage` function from Nixpkgs. This is discussed in the next section.

Remember, another overlay can override anything in Nixpkgs or provided by a previous overlay. If building a package involves building some intermediate artifacts, you might want to expose those artifacts in the distributed overlay. Distributing overlays enables others to use the overlay and override these intermediate artifacts to get a different build.

## Making applications with `callPackage`<a id="sec-4-5"></a>

The scaffolded project contains the definition of an application in `nix/my-app.nix`, which has been written in a conventional style:

```nix
{
  writeShellApplication,
  curl,
  w3m,
}:

writeShellApplication {
  name = "my-app";
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

# Updating dependencies<a id="sec-5"></a>

You'll notice the first time you run a `nix` command against your newly scaffolded project, a `flake.lock` lock file will be generated. Flake inputs can point to mutable references like Git repository branches. The lock file pins references to a specific snapshot retrieved.

This lock file should be checked in with your source. This file is what makes your build repeatable.

When we want to update all the dependencies in our lock file, we can run:

```sh
nix flake update
```

# Next Steps<a id="sec-6"></a>

This guide and the scaffolded project used as an example, show how to make packages providing a simple shell script. You will likely want to start making packages for other languages.

Nix has an [official learning starting point](https://nixos.org/learn.html), that is a good next step. In particular, you will find yourself reading the [Nixpkgs manual](https://nixos.org/nixpkgs/manual).

The guides included in this project cover more of the language-agnostic aspects of Nix and Nixpkgs. Each programming language ecosystem has its set of unique requirements and idiosyncrasies. Nixpkgs provide functions to assist with each language, which can lead to some divergent experiences when packaging and developing with Nix. The Nixpkgs manual has [dedicated sections for each language](https://nixos.org/manual/nixpkgs/stable/#chap-language-support). Eventually, you will find yourself diving into [Nixpkgs source code](https://github.com/NixOS/nixpkgs).

The Nix ecosystem is vast. This project and documentation illustrate just a small sample of what Nix can do.
