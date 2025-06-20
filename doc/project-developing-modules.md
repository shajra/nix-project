- [About this document](#sec-1)
- [Prerequisites](#sec-2)
- [Scaffolding](#sec-3)
- [Motivating using `flake-parts`](#sec-4)
- [Using `flake-parts`](#sec-5)
- [Authoring your own flake module](#sec-6)
  - [First understanding general Nix modules](#sec-6-1)
  - [From Nix modules to flake modules](#sec-6-2)
  - [A common flake module pattern](#sec-6-3)
- [Distributing your flake module](#sec-7)
- [Next steps](#sec-8)


# About this document<a id="sec-1"></a>

This document is a continuation of [Flakes Basics Development Guide](project-developing-basics.md). Specifically, it explains how to author [`flake-parts`](https://github.com/hercules-ci/flake-parts) modules, to address some points of tension when using the plain flakes API.

# Prerequisites<a id="sec-2"></a>

Before diving into flake-parts modules, you should be familiar with the [Flakes Basics Development Guide](project-developing-basics.md).

Additionally, the following guides may be helpful:

-   [Introduction to Nix and Motivations to Use It](nix-introduction.md)
-   [Nix Installation and Configuration Guide](nix-installation.md)
-   [Introduction to the Nix Programming Language](nix-language.md)

# Scaffolding<a id="sec-3"></a>

If you followed the [Flakes Basics Development Guide](project-developing-basics.md), you already scaffolded a project using the provided `less` template, which by design doesn't use `flake-parts`. To follow along with this guide, you can scaffold a project from the `more` template, which illustrates usage of `flake-parts`:

```sh
nix --refresh \
    flake new \
    --template github:shajra/nix-project/main#more \
    /tmp/my-project-more  # or whereever you want your new project
```

    wrote: "/tmp/my-project-more/README.org"
    wrote: "/tmp/my-project-more/default.nix"
    wrote: "/tmp/my-project-more/flake.nix"
    wrote: "/tmp/my-project-more/nix/compat.nix"
    wrote: "/tmp/my-project-more/nix/module/my-module.nix"
    wrote: "/tmp/my-project-more/nix/module"
    wrote: "/tmp/my-project-more/nix/my-app.nix"
    wrote: "/tmp/my-project-more/nix/overlay.nix"
    wrote: "/tmp/my-project-more/nix"

Beyond what's in the `less` template, the `more` template also provides two files, `default.nix` and `nix/compat.nix` to support end users who have decided not to enable flakes in their Nix installation. These are standalone, and could be copied to any flake-based project. The provided [guide on using Nix without flakes](nix-usage-noflakes.md) illustrates how end users without flakes can use the `default.nix` and `nix/compat.nix` files in the scaffolded project. The [guide on using Nix with flakes](nix-usage-flakes.md) will match the experience of other users using flakes.

# Motivating using `flake-parts`<a id="sec-4"></a>

As covered in the [Flakes Basics Development Guide](project-developing-basics.md), the code in our `less` template has a few points of tension:

-   The `forAllSystems` boilerplate in [`flake.nix`](../examples/less/flake.nix), while not too many lines, is distracting.
-   Lots of dependencies in [`nix/overlay.nix`](../examples/less/nix/overlay.nix) seem to build slightly differently and we have to figure out how to place their results in the appropriate flake output.
-   If not for [`./config.nix`](../examples/less/config.nix), our flake can easily seem more like complicated code than a declarative configuration.

The `flake-parts` project addresses these issues by leaning an abstraction originating from the NixOS operating system called *Nix modules*. When used in the context of `flake-parts`, we call these modules *flake modules*.

A key observation to motivate the design of Nix modules are that our build configurations often starting with a tree of attributes (nested attribute sets), of an allowed schema. Then we perform some computation that might require some standard inputs, and end up with our tree extended with more attributes representing our build artifacts. Then these artifacts might become inputs for more computations. Iterating on this process, we keep on growing our tree until we have what we need.

To support this pattern a Nix module encapsulate one step of such a process:

-   inputs needed by all modules are defined and made available
-   configuration attribute paths and types are well-specified
-   the module has a transform to turn configuration to resultant paths/values
-   modules can import other modules as dependencies

Let's look at [the `more` template's `flake.nix`](../examples/more/flake.nix) for a concrete example of Nix modules as flake modules. The flake module in this file has the following structure:

```nix
{ withSystem, ... }:
  …
{
  imports = [
    inputs.nix-project.flakeModules.org2gfm
    inputs.devshell.flakeModule
    inputs.treefmt-nix.flakeModule
    nix/module/my-module.nix
  ];
  systems = (import systems-darwin) ++ (import systems-linux);
  perSystem = …;
  flake = …;
}
```

Similar to the plain flakes API, we have a function that can be passed a variety of input arguments. And we return attributes that give us an alternate API for defining flakes.

All of these attributes (`imports`, `systems`, `perSystem`, and `flake`) have been defined already as valid *options* for our module. If we use another attribute, or set them to values of the wrong type, the `flake-parts` API will throw an error with a helpful message.

Much of this can be implemented with a simple callback-based API. But modules give us some added benefits worth noting:

-   Modules can import other modules to get more *options* for new valid configuration attributes.
-   Options can declare how configuration merges if the same configuration is set differently by two different imported modules.
-   Options have a fairly elaborate type system helping us get nice error messages.

In summary, modules compose. The `imports` attribute, standard to all modules is central to composition. For example, if we want attributes that help us configure [`treefmt-nix`](https://github.com/numtide/treefmt-nix), we can import the [`treefmt-nix` flake module](https://flake.parts/options/treefmt-nix.html). This imports options for attributes we can validly set to configure our formatter:

```nix
{ ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    …
  ];
  perSystem = { ... }: {
    treefmt.programs = {
      deadnix.enable = true;
      nixfmt.enable = true;
      nixf-diagnose.enable = true;
    };
    …
  };
  …
}
```

The flake module will then handle setting up useful flake outputs. In the case of the `treefmt-nix` flake module, by default these include:

-   `formatter.<system>`, which is used by `nix fmt`
-   `checks.<system>.treefmt`, so `nix flake check` asserts all our code is formatted.

These are just defaults. You can control how the flake outputs are managed with the `treefmt-nix` module configuration.

Each module gives us a focused custom API (you might think of them as domain-specific languages). These little APIs make more clear the intent of our build, rather than having to see it through the code setting flake outputs. Modules abstract that part away.

Note that the configuration inputs of modules in the [`more` template's `flake.nix` ](../examples/more/flake.nix)look nearly identical to the [`less` template's `config.nix` file](../examples/less/config.nix). This is by pedagogical design. You don't need to have actual modules to factor your code in a modular style. This is what the `less` template illustrates.

By using `flake-parts`, you get

-   a little less boilerplate
-   more clear modular boundaries
-   and nice error checking/messages.

# Using `flake-parts`<a id="sec-5"></a>

To help get you started with `flake-parts`, this section covers its API at a high-level. You should eventually read the [official `flake-parts` documentation](https://flake.parts).

The following illustrates how to call the `flake-parts` API in the `outputs` attribute of a flake:

```nix
{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  outputs =
    inputs@{self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (topLevelModArgs: {
      …
    });
  …
}
```

Note that bindings we have in scope include our dependencies (bound to `inputs` above) and `flake-parts` top-level module arguments (bound to the `topLevelModArgs` attribute set above). These top-level module arguments are [documented fully in the `flake-parts` documentation](https://flake.parts/module-arguments.html).

If you don't need the top-level arguments to configure your modules, you can call `flake-parts` with a more straightforward form (just an attribute set instead of a function returning one):

```nix
{
    # …
    outputs = inputs@{ flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            # …
        };
}
```

As you can see from the `more` template's [`flake.nix`](../examples/more/flake.nix) file, `flake-parts` has us populate three attributes:

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

In `flake-parts`, the `flake` attribute is used for flake outputs that are the same for all target systems. The `flake` component of the attribute path is dropped in the final flake output path. For example, in the `more` template, `flake-part`'s `flake.overlays.default` ends up being just `overlays.default` in our project's final flake output.

Otherwise, all our system-specific outputs are returned by the function we set for the `perSystem` attribute. Notice the `perSystem` function has the following three bindings in scope:

-   the original flake inputs (`inputs` above)
-   top-level module arguments (`topLevelModArgs` above)
-   per-system module arguments (`perSystemModArgs` above)

The per-system module arguments are also [documented fully in the flake-parts documentation](https://flake.parts/module-arguments.html). These arguments help us avoid dealing with the system we're targeting.

For example, one of the per-system arguments is `pkgs`. If you use this argument, you are expected to have Nixpkgs bound as an input to the specially treated `nixpkgs` name.

For example, let's say we wanted to pass through GNU Hello as a package provided by our project. Without `flake-parts` we would access the `hello` package from the attribute path `inputs.nixpkgs.legacyPackages.<system>.hello`. With `flake-parts`' `perSystem` API, we access it simply with `pkgs.hello`.

The following illustrates this GNU Hello example in a tiny, but complete `flake.nix` file using `flake-parts`:

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

Hopefully, the improvement in this API is appreciable upon inspection. We don't have to mess with a parameterization for the system. And merging everything for each system is done for us.

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

# Authoring your own flake module<a id="sec-6"></a>

Even if you enjoy and use `flake-parts`, community adoption of the project has been partial. While the potential is there for a large ecosystem of publicly distributed flake modules, what we have feels useful, but far from complete.

That doesn't mean you have to abandon `flake-parts` completely. You can mix the styles of the `more` and the `less` templates, using flake modules when they exist for your purpose.

However, if you really want to lean harder into `flake-parts`, you might have motivation to author your own flake module, even if you opt not to distribute it publicly.

## First understanding general Nix modules<a id="sec-6-1"></a>

Flake modules are a specialized instance of the more general concept of Nix modules, originally created to configure the NixOS operating system. This section discusses the general form of Nix modules in preparation for subsequent sections on the specifics of flake modules.

We're only going to cover Nix modules at a high-level. More complete references on the subject include

-   [the NixOS manual's section on modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
-   [the NixOS wiki page on modules](https://nixos.wiki/wiki/NixOS_modules).

Modules come in a few forms, ranging

-   from a simple module attribute set
-   to a function taking an attribute set of useful arguments and returning the module attribute set.

The module attribute set can also come in a few forms. The most general form has the following three attributes:

```nix
{
  imports = [
    # paths to other modules
  ];
  options = {
    # properties defining the valid attribute paths and types of configuration.
  };
  config = {
    # the configuration, conforming to all options in the current or imported
    # module.
  };
}
```

If there are no options declared by a module, the following form is also valid:

```nix
{
  imports = [
    # paths to other modules
  ];
  # the configuration, conforming to all options in imported modules.
}
```

The parameters passed to the function-form of a Nix module varies depending on the type of module. Common to most implementations (including flake modules) include

-   `config`, the "final" attribute set of all configuration
-   `options`, the "final" attribute set of all options
-   `lib`, a useful library of functions from Nixpkgs.

Notice that what to an end user looks just like configuration is actually a module that doesn't declare any options, but rather gets all it's options implicitly through imports.

## From Nix modules to flake modules<a id="sec-6-2"></a>

You can think of flake modules as normal Nix modules with some built-in modules implicitly imported. These modules provide options for the following configuration attributes:

-   `system`
-   `perSystem`
-   `flake`

The `flake` configuration is special, because this is what will actually become our final flake outputs. It's good to exercise restraint in exposing new outputs on a flake. These will show up in `nix flake show`. Too many non-standard outputs undermines the benefit of having a standard in the first place.

Instead, it's much more conventional to have custom configuration for a module on `perSystem`, which are not exposed on the flake unless our module does so explicitly (using `flake`). This works out most of the time because most custom build work is actually system-specific.

It's important to understand that the type of `perSystem` is a itself a module, So with `flake-parts` we're authoring a inner module (`perSystem`) while also authoring an outer module for the API. All common aspects of Nix modules apply to both. For instance, both can be simplified from a function to just an attribute set if you don't require module arguments.

## A common flake module pattern<a id="sec-6-3"></a>

Since custom flake module configuration is so commonly defined on `perSystem`, many flake modules have the following form:

```nix
{ flake-parts, ... }:

{
  options.perSystem = flake-parts.lib.mkPerSystemOption (
    { config, lib, pkgs, ... }:
    {
      _file = ./this-module.nix
      options = {
        # Declare per-system options
      };

      config = {
        # Provide per-system configuration
      };
    }
  );
}
```

The `mkPerSystemOption` function is a wrapper that decorates our `perSystem` module to work with `flake-parts`' documentation framework. To have a functioning flake, it's not strictly needed. The `_file` attribute is also optional for documentation purposes.

As a concrete illustration the `more` template includes a small example of a flake module:

```nix
{
  config,
  flake-parts-lib,
  lib,
  ...
}:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      moduleApp = pkgs.writeShellApplication {
        name = "my-module-app";
        meta.description = "Example application provided by example module";
        text = ''
          echo "${config.my-module.message}"
        '';
      };
    in
    {
      _file = ./my-module.nix;
      options.my-module = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable the my-module module";
        };

        message = lib.mkOption {
          type = lib.types.str;
          default = "Greetings, World!";
          description = "Greeting to display";
        };
      };

      config = lib.mkIf config.my-module.enable {
        packages.my-module-app = moduleApp;
        apps.my-module-app = {
          type = "app";
          program = "${moduleApp}/bin/my-module-app";
        };
      };
    }
  );

  config.flake.flakeModules.my-module = lib.mkIf (builtins.any (c: c.my-module.enable or false) (
    builtins.attrValues config.allSystems
  )) (import ./my-module.nix);
}
```

This module introduces two per-system configuration options:

-   `enable`, a boolean to turn the feature on/off
-   `message`, a configurable message to echo to standard out

If the module is imported, and the feature is enabled, then a system-specific `my-module-app` package and app are published on the flake.

To show how we might affect a non-system-specific flake output like `flakeModules` based on the results of a per-system configuration, we self-publish the `my-module` module, only if enabled, but we look for this enablement on configurations for all systems (`config.allSystems`).

Note how we use `lib.mkIf` to conditionally publish the package and app on the flake. We need these kinds of functions, because lexically in the module, we don't know yet if the feature is actually going to be used or not.

Also, this is the first time we're seeing how options are defined. This example illustrates just a small sample of available types. See [the NixOS manual sections on modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules) for details on how expressive these types can get.

We can see this module used in the [`more` template `flake.nix`](../examples/more/flake.nix):

```nix
{
  imports = [
    # …
    nix/module/my-module.nix
  ];
  perSystem = {
    # …
    my-module.enable = true;
  };
  # …
}
```

# Distributing your flake module<a id="sec-7"></a>

As we've seen in the discussion above, modules are expected to be distributed on the `flakeModules` output attribute of a flake. This is not yet a standard in the flakes API, but it's a convention that users of `flake-parts` have settled on.

You might see people publishing single modules on `flakeModule`, but this older style is clearly less extensible and inconsistent with other flake configurations (`packages`, `apps`, `overlays`, etc). If you have only one flake module to publish, use `flakeModules.default` instead of `flakeModule`.

# Next steps<a id="sec-8"></a>

This document has covered a lot of topics to get just a high-level explanation of how to author flake modules. Here's a compilation of relevant resources to explore more:

-   [The Nix wiki page on flakes](https://nixos.wiki/wiki/Flakes)
-   [The Nix manual's section on flake inputs](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-references)
-   [`flake-parts` documentation](https://flake.parts)
-   [The NixOS manual's section on modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
-   [The Nix wiki's page on modules](https://nixos.wiki/wiki/NixOS_modules)

Beyond the example module in the `more` template, Nix-project provides [some small modules](../nix/module) you may find instructive to look at.
