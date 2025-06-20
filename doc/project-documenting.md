- [About this document](#sec-1)
- [About Org2gfm](#sec-2)
- [Prerequisites](#sec-3)
- [Usage](#sec-4)
  - [Calling `org2gfm` directly](#sec-4-1)
  - [Using `org2gfm` from a project scaffolded by Nix-project](#sec-4-2)
- [Org2gfm design](#sec-5)
  - [GitHub Flavored Markdown (GFM) exporting only](#sec-5-1)
  - [All evaluation should exit non-zero](#sec-5-2)
  - [No evaluation when exporting](#sec-5-3)
- [Org2gfm recommended usage for source blocks](#sec-6)
  - [Evaluation of source blocks](#sec-6-1)
  - [Results of source blocks](#sec-6-2)
  - [Exporting source blocks](#sec-6-3)


# About this document<a id="sec-1"></a>

This document shows one way to document your code with the `org2gfm` script provided by this project, Nix-project. This script converts [Emac's Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html) files into [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/). It can evaluate all source blocks in the Org files to generate results to include in the documentation or check that source code snippets work as intended.

If you're reading this document right now as Markdown it was generated with `org2gfm`.

As its name indicates, `org2gfm` currently only exports to GFM, so this script only applies to projects maintained on GitHub.

You can install `org2gfm` with Nix to use stand-alone, or you can get the script integrated into a Nix-based project scaffolded with Nix-project as discussed in the [project development guide](project-developing-basics.md).

Finally, this document explains `org2gfm`'s design decisions and recommends a style for its use.

# About Org2gfm<a id="sec-2"></a>

Documenting programming projects often requires embedding code snippets. We generally want to check that these snippets are well-formed. Other times, we might want to process the code to obtain a result to embed in the document.

Some may recognize this as similar to [literate programming](https://en.wikipedia.org/wiki/Literate_programming). The Emacs text editor has long has long shipped with a feature called [Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html) used for this kind of documentation. The Org-mode input files used by `org2gfm` are more-or-less human-readable markdown files, though they support a lot of features for document processing.

Emacs can be run in a headless mode from the command-line to avoid bringing up an entire text editor to generate documentation. This is what `org2gfm` does. The script manages the execution of Emacs on the user's behalf.

Because Nix provides `org2gfm` and all its dependencies, its instance of Emacs is safely isolated and hidden from any other instance of Emacs a user might have installed otherwise. This isolation is helpful because instances of Emacs can be finicky to keep configured correctly.

We can also call `org2gfm` with an invocation of `nix shell` to ensure our documentation is executed in a controlled environment. This way, any commands referenced by code snippets can be guaranteed to be on `PATH`. This sandboxing makes documentation generation even more repeatable, regardless of which machine we generate documentation on. New projects scaffolded with Nix-project are set up this way to call `org2gfm` with `nix shell`.

The `org2gfm` is very small. Most of the work is done by Emacs. The script mainly simplifies the complexity of configuring and running Emacs.

# Prerequisites<a id="sec-3"></a>

You should have some familiarity with [Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html) and its terminology first before continuing.

You need Nix installed to use `org2gfm`.

If you're new to Nix consider reading the provided [introduction](nix-introduction.md).

If you don't have Nix set up yet, see the provided [installation and configuration guide](nix-installation.md). This guide will show you how to use `org2gfm` both with and without Nix's experimental flakes feature enabled. More options are available with flakes.

If you don't know how to use basic Nix commands, see the provided [Nix end user guide](nix-usage-flakes.md).

If you want to integrate documentation generation with a project scaffolded by Nix-project (this project), see the [project development guide](project-developing-basics.md).

# Usage<a id="sec-4"></a>

## Calling `org2gfm` directly<a id="sec-4-1"></a>

You can call `org2gfm` directly, either with or without flakes. Using flakes, you can run `org2gfm` directly from GitHub with `nix shell` without even installing `org2gfm`:

```sh
nix --extra-experimental-features 'nix-command flakes' \
    shell \
    github:shajra/nix-project#org2gfm \
    --command org2gfm
```

By default, `org2gfm` finds all Org files recursively from the current directory and exports each one to a sibling Markdown file.

If called with the `--evaluate` switch, the code snippets in the Org file are evaluated, changing the Org file in place.

> **<span class="underline">WARNING</span>**: Since `org2gfm --evaluate` writes over files in-place, source control is highly recommended to protect against the loss of documentation.

If you don't want to evaluate all Org files found, files can be explicitly specified as positional arguments, or the `--exclude` switch can be used to exclude filenames matching a regular expression.

We can use the `--ignore-environment` of `nix shell` to sandbox execution of `org2gfm`. Sandboxing clears out all environment variables. If we want to keep a few, we can use `nix shell`'s `--keep` switch.

If we want more packages on the path than `org2gfm` we can reference more flake packages. Here's an example:

```sh
nix --extra-experimental-features 'nix-command flakes' \
    shell \
    --ignore-environment \
    --keep LANG \
    --keep LOCALE_ARCHIVE \
    github:shajra/nix-project#org2gfm \
    nixpkgs#coreutils \
    --command org2gfm --evaluate
```

Here, we're running the latest released version of `org2gfm` found on GitHub in a sandboxed environment. Only the `LANG` and `LOCALE_ARCHIVE` environment variables are kept from the calling environment. The only tools on the path are `org2gfm` and a variety of Unix tools provided by the `coreutils` package, which is taken from the latest `nixpkgs-unstable` release of Nixpkgs.

You can still use `org2gfm` if you have decided not to enable `flakes` experimental feature. However, you should still use `nix-command`. Here's an example to compliment the example using flakes from the previous section:

```sh
nix --extra-experimental-features 'nix-command' \
    shell \
    --ignore-environment \
    --keep LANG \
    --keep LOCALE_ARCHIVE \
    --file https://github.com/shajra/nix-project/archive/main.tar.gz \
    currentSystem.packages.org2gfm \
    currentSystem.legacyPackages.nixpkgs.coreutils \
    --command org2gfm --evaluate
```

Note when using `nix shell` with the `--file`, we need all the packages for our sandbox to come from a single file (we can only use `--file` once). As a convenience, the Nix-project's `default.nix` file (accessed directly from a tarball retrieved from GitHub above) includes a snapshot of the latest stable release of Nixpkgs. As illustrated above, we access this under `currentSystem.legacyPackages.nixpkgs`.

If you need packages beyond what's provided in the Nixpkgs snapshot, you need to create your own Nix expression in a file, including everything you need for your `nix shell` execution. Explaining how is beyond the scope of this document.

## Using `org2gfm` from a project scaffolded by Nix-project<a id="sec-4-2"></a>

As discussed in the [project development guide](project-developing-basics.md) we can scaffold a project with `nix flake new`. For example, to scaffold with the `less` template:

```sh
nix --refresh \
    flake new \
    --template github:shajra/nix-project/main#less \
    /tmp/my-project  # or whereever you want your new project
```

A freshly scaffolded project will have a `README.org` file in its root. This file has an example call to `whoami` in it. When you call `nix develop --command project-doc-gen`, you'll run `org2gfm` in a sandboxed environment. Upon completion, the `README.org` file will be modified in place to include the result of the `whoami` call. Additionally, a `README.md` file is exported as a sibling document.

You can control the execution of `org2gfm` by modifying [`config.nix`](../examples/less/config.nix) of the `less` template, or modifying [`flake.nix`](../examples/more/flake.nix) of the `more` template, using options as [defined by the `org2gfm` flake module](../nix/module/org2gfm.nix).

# Org2gfm design<a id="sec-5"></a>

The `org2gfm` script provided by this project constrains the total flexibility of [Emac's Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html), particularly with respect to evaluation and exporting. This section discusses the design of `org2gfm` and how to use it as intended.

## GitHub Flavored Markdown (GFM) exporting only<a id="sec-5-1"></a>

One obvious constraint of Org2gfm is that it only exports [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/). Many projects are hosted on GitHub, and GitHub's online rendering of Markdown files is the first documentation a user encounters. We want to ensure that users find excellent documentation next to the code.

## All evaluation should exit non-zero<a id="sec-5-2"></a>

`org2gfm` will halt with an error if any code block exits with a non-zero status. If you want to illustrate an error condition, you should handle it in the code block. This way, the user has confidence that they can reproduce the code block successfully, even when illustrating an error case.

## No evaluation when exporting<a id="sec-5-3"></a>

You can evaluate source blocks within the original Org files with vanilla Org-mode. But when you export the Org files to another format, the evaluation occurs again. This reevaluation can be confusing because side-effecting functions (even the `date` command) can lead to different evaluations between the Org and the exported files. By convention, we can try to minimize and manage these differences, but it's tedious to look at two files to check if side-effects have caused a problem in one file but not another.

Instead, `org2gfm` adds `(:eval . "no-export")` to `org-babel-default-header-args`, which makes a global default of disabling all evaluation during exporting. This way, we do all of our evaluations in the Org file, and these evaluated source blocks and their result blocks are exported verbatim. Code or results exported in the Markdown file should also exist in the Org file. However, not everything in the Org file needs to be exported.

The `org-babel-default-header-args` setting is just a default. If you like, you can always override this default with explicit header arguments.

# Org2gfm recommended usage for source blocks<a id="sec-6"></a>

Figuring out [how Org-mode processes source blocks](https://orgmode.org/manual/Working-with-Source-Code.html#Working-with-Source-Code) can be confusing. Hopefully, the defaults of `org2gfm` simplify our usage.

The following process to decide on arguments covers the most common cases. For less common cases, you still have the full array of all header arguments supported by Org-mode.

## Evaluation of source blocks<a id="sec-6-1"></a>

To start, for each source block, we have to choose how it evaluates, which we typically control with `:eval` header arguments:

| `:eval` Header Argument | Evaluated in Org file       | Evaluated in export |
|----------------------- |--------------------------- |------------------- |
| default                 | if called with `--evaluate` | no                  |
| `:eval no`              | no                          | no                  |
| `:eval yes`             | yes                         | yes                 |

If you call `org2gfm` with the `--evaluate` switch, all sources will be evaluated unless the block is explicitly set `:eval no`. Without this switch, `org2gfm` does not evaluate at all.

In general, we'd like to avoid using `:eval yes` because it leads to the possibility of our exported files unexpectedly differing from our source Org files. However, there are some instances where evaluation during export makes sense, for example, when taking advantage of [Noweb expansion](https://orgmode.org/manual/Noweb-Reference-Syntax.html#Noweb-Reference-Syntax) in exporting.

The official Org-mode documentation covers [more options for evaluation](https://orgmode.org/manual/Evaluating-Code-Blocks.html#Evaluating-Code-Blocks).

## Results of source blocks<a id="sec-6-2"></a>

There are a lot of options for controlling the [results of an evaluated source block](https://orgmode.org/manual/Results-of-Evaluation.html) with the `:results` header.

Note that if not evaluating a block (for example, with `:eval no`), you don't need the `:results` header at all.

Here are typical ways to use the `:result` header:

| `:results` Header Argument                   | Collection           | Handling             |
|-------------------------------------------- |-------------------- |-------------------- |
| `:results value` (default)                   | evaluated value      | replaced in Org file |
| `:results output`                            | from standard output | replaced in Org file |
| `:results value silent` or `:results silent` | evaluated value      | discarded            |
| `:results output silent`                     | from standard output | discarded            |

When evaluating source code, we need to consider whether the results are collected as the value we get after evaluating the code as an expression, or whether the results are collected from standard output as a side effect. Consider Python's `print("hello")`. The returned value of printing is Python's `None`. But when the code is executed, we can collect the string "hello" from standard output.

We also want to decide whether our results are placed below the evaluated source block in the Org file, replacing old results if there. This replacement is done by default. Otherwise, with `silent`, we can evaluate the source block but not render the results for the reader.

A helpful tip is to name all your evaluating source blocks that have not been silenced. This is done with "name" line above the source block:

    #+name: whoami
    #+begin_src sh :results output :exports both
    whoami
    #+end_src

When you name a source block, you will get better error reporting by `org2gfm` if a source block exits with a non-zero result.

## Exporting source blocks<a id="sec-6-3"></a>

Finally, we decide what to export into the Markdown file. Fortunately, the [options for the `:exports` header argument](https://orgmode.org/manual/Exporting-Code-Blocks.html#Exporting-Code-Blocks) are more straightforward:

| `:exports` Header Argument | Exports                    |
|-------------------------- |-------------------------- |
| `:exports code` (default)  | code only                  |
| `:exports both`            | both code and results      |
| `:exports none`            | nothing                    |
| `:exports results`         | results only (less common) |

Note that by design, `org2gfm` only exports code or results of source blocks in the Org file (since there's no evaluation of the export). So `:results silent :exports both` will only output code, because there are no results to export.

Also, note that you can prevent exporting of entire subtrees by [tagging](https://orgmode.org/manual/Tags.html#Tags) headings in an outline with [`noexport`](https://orgmode.org/manual/Export-Settings.html#Export-Settings).
