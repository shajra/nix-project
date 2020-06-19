- [Org2gfm Design](#sec-1)
  - [GitHub Flavored Markdown exporting only](#sec-1-1)
  - [No evaluation when exporting](#sec-1-2)
- [Org2gfm Recommended Usage For Source Blocks](#sec-2)
  - [Evaluation of source blocks](#sec-2-1)
  - [Results of source blocks](#sec-2-2)
  - [Exporting source blocks](#sec-2-3)

The `org2gfm` script provided by this script constrains the full flexibility of [Emac's Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html), particularly with respect to evaluation and exporting. This document discusses the design of `org2gfm` and how to use it as intended.

You should have some familiarity with Org-mode and its terminology first before reading further.

# Org2gfm Design<a id="sec-1"></a>

## GitHub Flavored Markdown exporting only<a id="sec-1-1"></a>

One obvious constraint of Org2gfm is that it only exports [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/). This assumes that all projects are hosted on GitHub, but if they are then GitHub's online rendering of markdown files is the first documentation a user encounters when finding the code. It's nice to make sure users find great documentation next to the code itself.

## No evaluation when exporting<a id="sec-1-2"></a>

With vanilla Org-mode, You can evaluate source blocks within the original Org files. But when you export the Org files to another format evaluation occurs again. This can be confusing, because side-effecting functions (even the `date` command), can lead to different evaluations between the Org file and the exported file. By convention, we can try to minimize and manage these differences, but it's tedious to have to look at two files to check if side-effects have caused a problem in one file, but not another.

Instead, `org2gfm` adds `(:eval . "no-export")` to `org-babel-default-header-args`, which makes a global default of disabling all evaluation during exporting. This way, we do all of our evaluations in the Org file, and these evaluated source blocks and their result blocks are exported verbatim. Code or results exported in the markdown file should also exist in the Org file. However, not everything in the Org file needs to be exported.

The `org-babel-default-header-args` setting is just a default. If you like, you can always override this default with explicit header arguments.

# Org2gfm Recommended Usage For Source Blocks<a id="sec-2"></a>

It can be confusing figuring out [how Org-mode processes source blocks](https://orgmode.org/manual/Working-with-Source-Code.html#Working-with-Source-Code). Hopefully, the defaults of `org2gfm` simplifies our usage.

The following process to decide on arguments covers a good majority of common cases. For less common cases, you still have the full array of all header arguments supported by Org-mode.

## Evaluation of source blocks<a id="sec-2-1"></a>

To start, for each source block, we have to chose how it evaluates, which we typically control with `:eval` header arguments:

| `:eval` Header Argument | Evaluated in Org file       | Evaluated in export |
|----------------------- |--------------------------- |------------------- |
| default                 | if called with `--evaluate` | no                  |
| `:eval no`              | no                          | no                  |
| `:eval yes`             | yes                         | yes                 |

If you call `org2gfm` with the `--evaluate` switch, then all sources will be evaluated unless the block is explicitly set `:eval no`. Without this switch, `org2gfm` performs no evaluation at all.

In general, we'd like to avoid using `:eval yes`, because it leads to the possibility of our exported files unexpectedly differing from our source Org files. However, there are some instances where evaluation during export makes sense, for instance when taking advantage of [Noweb expansion](https://orgmode.org/manual/Noweb-Reference-Syntax.html#Noweb-Reference-Syntax) in exporting.

The official Org-mode documentation covers [more options for evaluation](https://orgmode.org/manual/Evaluating-Code-Blocks.html#Evaluating-Code-Blocks).

## Results of source blocks<a id="sec-2-2"></a>

There's a lot of options for controlling the [results of an evaluated source block](https://orgmode.org/manual/Results-of-Evaluation.html) with the `:results` header.

Note that if not evaluating a block (for example with `:eval no`), you don't need the `:results` header at all.

Here are typical ways to use the `:result` header:

| `:results` Header Argument                   | Collection           | Handling             |
|-------------------------------------------- |-------------------- |-------------------- |
| `:results value` (default)                   | evaluated value      | replaced in Org file |
| `:results output`                            | from standard output | replaced in Org file |
| `:results value silent` or `:results silent` | evaluated value      | discarded            |
| `:results output silent`                     | from standard output | discarded            |

When evaluating source code, we need to consider whether the results are collected as the value we get after evaluating the code as an expression, or whether the results are collected from standard output as a side effect. For instance, consider Python's `print("hello")`. The returned value of printing is Python's `None`. But when the code is executed we can collect the string "hello" from standard output.

We also want to decide whether our results are placed below the evaluated source block in the Org file, replacing old results if there. This is done by default. Otherwise, with `silent` we can evaluate the source block, but not render the results for the reader.

## Exporting source blocks<a id="sec-2-3"></a>

Finally we decide what will be exported into the markdown file. Fortunately, the [options for the `:exports` header argument](https://orgmode.org/manual/Exporting-Code-Blocks.html#Exporting-Code-Blocks) are more straight-forward:

| `:exports` Header Argument | Exports                    |
|-------------------------- |-------------------------- |
| `:exports code` (default)  | code only                  |
| `:exports both`            | both code and results      |
| `:exports none`            | nothing                    |
| `:exports results`         | results only (less common) |

Note that by design, `org2gfm` only exports code or results of source blocks that exist in the Org file (since there's no evaluation of the export). So `:results silent :exports both` will only output code, because there's no results to export.

Also, note that you can prevent exporting of entire subtrees by [tagging](https://orgmode.org/manual/Tags.html#Tags) headings in an outline with [`noexport`](https://orgmode.org/manual/Export-Settings.html#Export-Settings).
