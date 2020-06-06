- [Org2gfm Design](#sec-1)
  - [GitHub Flavored Markdown exporting only](#sec-1-1)
  - [No evaluation when exporting](#sec-1-2)
- [Org2gfm Recommended Usage](#sec-2)

The `org2gfm` script provided by this script constrains the full flexibility of [Emac's Org-mode](https://www.gnu.org/software/emacs/manual/html_node/emacs/Org-Mode.html), particularly with respect to evaluation and exporting. This document discusses the design of `org2gfm` and how to use it as intended.

You should have some familiarity with Org-mode and its terminology first before reading further.

# Org2gfm Design<a id="sec-1"></a>

## GitHub Flavored Markdown exporting only<a id="sec-1-1"></a>

One obvious constraint of Org2gfm is that it only exports [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/). This assumes that all projects are hosted on GitHub, but if they are then GitHub's online rendering of markdown files is the first documentation a user encounters when finding the code. It's nice to make sure users find great documentation next to the code itself.

## No evaluation when exporting<a id="sec-1-2"></a>

With vanilla Org-mode, You can evaluate source blocks within the original Org files. But when you export the Org files to another format evaluation occurs again. This can be confusing, because side-effecting functions (even the `date` command), can lead to different evaluations between the Org file and the exported file. By convention, we can try to minimize and manage these differences, but it's tedious to have to look at two files to check if side-effects have caused a problem in one file, but not another.

Instead, `org2gfm` adds `(:eval . "no-export")` to `org-babel-default-header-args`, which makes a global default of disabling all evaluation during exporting. This way, we do all of our evaluations in the Org file, and these evaluated source blocks and their result blocks are exported verbatim. Any code or result exported in the markdown file must also exist in the Org file. However, not everything in the Org file must be exported.

The `org-babel-default-header-args` setting is just a default. If you like, you can always override this default with explicit header arguments.

# Org2gfm Recommended Usage<a id="sec-2"></a>

Because of the constraints of `org2gfm`, you shouldn't need all [the header arguments supported for source blocks](https://orgmode.org/manual/Working-with-Source-Code.html#Working-with-Source-Code). The following process to decide on arguments covers a good majority of common cases.

To start, for each source block, we have to chose how it evaluates:

| `:eval` Header Argument | Evaluated                   |
|----------------------- |--------------------------- |
| default                 | if called with `--evaluate` |
| `:eval no`              | no evaluation               |

If you call `org2gfm` with the `--evaluate` switch, then all sources will be evaluated unless the block is explicitly set `:eval no`. Without this switch, `org2gfm` performs no evaluation at all.

Next we decide whether evaluated results will be replaced/set in the Org file:

| `:results` Header Argument | Results if Evaluated            |
|-------------------------- |------------------------------- |
| default                    | replaced in Org file as a table |
| `:results output`          | replaced in Org file as text    |
| `:results silent`          | no output replaced in Org file  |

By default the results of an evaluation is output below the source block in the Org file as a table. This output is replaced upon subsequent evaluations. With `:results output` this output is presented as text instead of a table. It's also possible to suppress output with `:results silent`. This way, the evaluation happens as a side-effect, but we ignore the output of the command.

Finally we decide what will be exported into the markdown file.

| `:exports` Header Argument | Exports               |
|-------------------------- |--------------------- |
| default                    | code only             |
| `:exports both`            | both code and results |
| `:exports none`            | nothing               |

Note that by design, `org2gfm` only exports code or results of source blocks that exist in the Org file (since there's no evaluation of the export). So `:results silent :exports both` will only output code, because there's no results to export.

Also, note that you can prevent exporting of entire subtrees by [tagging](https://orgmode.org/manual/Tags.html#Tags) headings in an outline with [`noexport`](https://orgmode.org/manual/Export-Settings.html#Export-Settings).
