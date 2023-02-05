-   [About this document](#sec-1)
-   [Prerequisites](#sec-2)
-   [Level of commitment/risk](#sec-3)
-   [Nix package manager installation](#sec-4)
-   [Cache setup](#sec-5)
-   [Setting up experimental features](#sec-6)

This document explains how to

-   install [the Nix package manager](<https://nixos.org/nix>)
-   set up Nix to download pre-built packages from a cache (optionally)
-   set up the Nix's experimental flakes feature (optionally)

If you're unsure if you want to enable flakes or not, read the provided [introduction to Nix](nix-motivation.md).

This project supports - Linux on x86-64 machines- MacOS on x86-64 machines- MacOS on ARM64 machines (M1 or M2).

All we need to use this project is to install Nix, which this document covers. Nix can be installed on a variety of Linux and Mac systems. Nix can also be installed in Windows via the Windows Subsystem for Linux (WSL). Installation on WSL may involve steps not covered in this documentation, though.

Note, some users may be using [NixOS](<https://nixos.org>), a Linux operating system built on top of Nix. Those users already have Nix and don't need to install it separately. To use this project, you don't need to use NixOS as well.

Unless you're on NixOS, you're likely already using another package manager for your operating system already (APT, DNF, etc.). You don't have to worry about Nix or packages installed by Nix conflicting with anything already on your system. Running Nix along side other package managers is safe.

All the files of a Nix package are located under \`/nix\` a directory, well isolated from any other package manager. Nix won't touch critical directories under \`/usr\` or \`/var\`. Nix then symlinks files under \`/nix\` to your home directory under dot-files like \`~/.nix-profile\`. There is also some light configuration under \`/etc/nix\`.

Hopefully this alleviates any worry about installing a complex program on your machine. Uninstallation is not too much more than deleting everything under \`/nix\`.

> ****<span class="underline">NOTE:</span>**** You don't need this step if you're running NixOS, which comes with Nix baked in.

If you don't already have Nix, [the official installation script](<https://nixos.org/download.html#download-nix>) should work on a variety of UNIX-like operating systems. If you're okay with the script calling \`sudo\` you can install Nix on a non-WSL machine with the following recommended command:

\`\`\`bash sh <(curl -L <https://nixos.org/nix/install>) &#x2013;daemon \`\`\`

The \`&#x2013;daemon\` switch installs Nix in the multi-user mode, which is generally recommended (single-user installation with \`&#x2013;no-daemon\` instead is recommended for WSL). The script reports everything it does and touches.

After installation, you may have to exit your terminal session and log back in to have environment variables configured to put Nix executables on your \`PATH\`.

The Nix manual describes [other methods of installing Nix](<https://nixos.org/manual/nix/stable/installation/installation.html>) that may suit you more. If you later want to uninstall Nix, see the [uninstallation steps documented in the Nix manual](<https://nixos.org/manual/nix/stable/installation/installing-binary.html#uninstalling>).

This project pushes built Nix packages to [Cachix](<https://cachix.org>) as part of its [continuous integration](<https://github.com/shajra/nix-project/actions>). It's recommended to configure Nix to use shajra.cachix.org as a Nix **substituter**. Once configured, Nix will pull down pre-built packages from Cachix, instead of building them locally (potentially saving a lot of time). This augments Nix's default substituter that pulls from cache.nixos.org.

You can configure shajra.cachix.org as a supplemental substituter with the following command:

\`\`\`sh nix run \\ &#x2013;file <https://cachix.org/api/v1/install> \\ cachix \\ &#x2013;command cachix use shajra \`\`\`

Cachix is a service that anyone can use. You can call this command later to add substituters for someone else using Cachix, replacing “shajra” with their cache's name.

If you've just run a multi-user Nix installation and are not yet a trusted user in \`/etc/nix/nix.conf\`, this command may not work. But it will report back some options to proceed.

One option sets you up as a trusted user, and installs Cachix configuration for Nix locally at \`~/.config/nix/nix.conf\`. This configuration will be available immediately, and any subsequent invocation of Nix commands will take advantage of the Cachix cache.

You can alternatively configure Cachix as a substituter globally by running the above command as a root user (say with \`sudo\`), which sets up Cachix directly in \`/etc/nix/nix.conf\`. The invocation may give further instructions upon completion.

This project can take advantage of two experimental Nix features:

-   \`nix-command\`
-   \`flakes\`

The provided [introduction to Nix](nix-motivation.md) covers in detail what these features are and can help you decide whether you want to enable them.

As you can guess, the \`flakes\` feature enables flakes functionality in Nix. The \`nix-command\` feature enables a variety of subcommands of Nix's newer \`nix\` command-line tool, some of which allow us to work with flakes.

There is a way to use flakes local to just a single command-line invocation by using \`nix &#x2013;extra-experimental-features 'nix-command flakes' …\`, so users avoiding using flakes can try out using flakes with little commitment. For those users, this can be useful to set to a shell alias.

As discussed in the introduction, \`nix-command\` is actually enabled by default. You don't need to enable it explicitly (though you could disable it).

To use flakes there are two things we need to do:

1.  make sure the version we're at least on Nix 2.4
2.  enable both the \`nix-command\` and \`flakes\` experimental features.

Since the latest release of Nix is already at 2.13, if you installed Nix recently as per the instructions above, you should be on a recent-enough version:

\`\`\`sh nix &#x2013;version \`\`\`

nix (Nix) 2.11.0

The easiest way to turn on experimental features is to create a file \`~/.config/nix/nix.conf\` if it doesn't already exist, and in it put the following line:

\`\`\`text experimental-features = nix-command flakes \`\`\`

Then you should see that the appropriate features are enabled:

\`\`\`sh nix show-config | grep experimental-features \`\`\`
