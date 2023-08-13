- [About this project](#sec-1)
- [Release](#sec-2)
- [License](#sec-3)
- [Contribution](#sec-4)

[![img](https://github.com/shajra/nix-project/workflows/CI/badge.svg)](https://github.com/shajra/nix-project/actions)

# About this project<a id="sec-1"></a>

This project, Nix-project, assists the setup of other projects with the [Nix package manager](https://nixos.org/nix) leaning on [flakes](https://nixos.wiki/wiki/Flakes), an experimental Nix feature.

Specifically, this project helps

-   scaffold new projects
-   maintain dependencies, which may mix different language ecosystems
-   generate Github-oriented documentation with evaluated code blocks
-   build and distribute packages, binary or otherwise.

This source's [doc directory](doc) provides a variety of documents to not only help you use this project, but also to get an introduction to the Nix ecosystem.

Among other benefits, Nix gives us an incredible amount of control and repeatability of our software projects. If you don't know much about Nix, consider reading the following provided guides:

-   [Introduction to Nix and motivations to use it](doc/nix-introduction.md)
-   [Nix installation and configuration guide](doc/nix-installation.md)
-   [Nix end-user guide](doc/nix-usage-flakes.md)
-   [Introduction to the Nix programming language](doc/nix-language.md)

If you know something about Nix, then these documents will help you get started using this project:

-   [Developing a Nix project with Nix-Project](doc/project-developing.md)
-   [Documenting a Nix project with Nix-project](doc/project-documenting.md)

# Release<a id="sec-2"></a>

The "main" branch of the GitHub repository has the latest released version of this code. There is currently no commitment to either forward or backward compatibility.

"user/shajra" branches are personal branches that may be force-pushed to. The "main" branch should not experience force-pushes and is recommended for general use.

# License<a id="sec-3"></a>

All files in this "nix-project" project are licensed under the terms of GPLv3 or (at your option) any later version.

Please see the [./COPYING.md](./COPYING.md) file for more details.

# Contribution<a id="sec-4"></a>

Feel free to file issues and submit pull requests with GitHub.

There is only one author to date, so the following copyright covers all files in this project:

Copyright © 2019 Sukant Hajra
