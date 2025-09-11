- [About this project](#sec-1)
- [Release](#sec-2)
- [License](#sec-3)
- [Contribution](#sec-4)

[![img](https://github.com/shajra/nix-project/workflows/CI/badge.svg)](https://github.com/shajra/nix-project/actions)

[![img](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fshajra%2Fnix-project%3Fbranch%3Dmain)](https://garnix.io/repo/shajra/nix-project)

# About this project<a id="sec-1"></a>

This project, Nix-project, assists the setup of other projects with the [Nix package manager](https://nixos.org/nix) leaning on [flakes](https://nixos.wiki/wiki/Flakes), an experimental Nix feature.

Specifically, this project helps

-   scaffold new projects
-   maintain dependencies, which may mix different language ecosystems
-   generate GitHub-oriented documentation with evaluated code blocks
-   build and distribute packages, binary or otherwise
-   document Nix and recommended practices for absolute beginners.

There's not a lot of code in Nix-project. Most of the work is done by Nix and third-party libraries. If you scaffolded a new project and removed the dependency on Nix-project, then you'd have a small project set up using Nix with recommended practices.

This source's [doc directory](doc) provides a variety of documents to not only help you use this project, but also to get an introduction to the Nix ecosystem.

Among other benefits, Nix gives us an incredible amount of control and repeatability of our software projects. If you don't know much about Nix, consider reading the following provided guides:

-   [Introduction to Nix and Motivations to Use It](doc/nix-introduction.md)
-   [Nix Installation and Configuration Guide](doc/nix-installation.md)
-   [Nix End-user Guide](doc/nix-usage-flakes.md)
-   [Introduction to the Nix Programming Language](doc/nix-language.md)

If you already know Nix basics, then these documents will help you get started using Nix-project:

-   [Flakes Basic Development Guide](doc/project-developing-basics.md)
-   [Flake Module (with `flake-parts`) Development Guide](doc/project-developing-modules.md)
-   [Documenting a Nix Project with Nix-project](doc/project-documenting.md)

# Release<a id="sec-2"></a>

The "main" branch of the GitHub repository has the latest released version of this code. There is currently no commitment to either forward or backward compatibility.

"user/shajra" branches are personal branches that may be force-pushed. The "main" branch should not experience force-pushes and is recommended for general use.

# License<a id="sec-3"></a>

All files in this "nix-project" project are licensed under the terms of GPLv3 or (at your option) any later version.

Please see the [./COPYING.md](./COPYING.md) file for more details.

# Contribution<a id="sec-4"></a>

Feel free to file issues and submit pull requests with GitHub.

There is only one author to date, so the following copyright covers all files in this project:

Copyright © 2019 Sukant Hajra
