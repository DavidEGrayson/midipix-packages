This repository contains PKGBUILD scripts for Midipix-related packages.

Using these scripts, you can build a working midipix toolchain
including GCC, Musl, psxscl, and ntctty for Arch Linux.

The `arch-linux` directory contains packages that are meant to be
compiled, installed, and executed on an Arch Linux system.  It would
not make much sense to copy the compiled package files to Windows
because they might contain Linux binaries.  The files installed by
these packages live in standard places like /usr/bin and /usr/lib, and
they are compiled using the default makepkg configuration of your Arch
Linux system.

The `cross` directory contains packages that are meant to be compiled
and installed on an Arch Linux system, but they are meant to be copied
to Windows to actually execute.  They should be compiled with the
makepkg configuration file `makepkg-nt64.conf`.

Arch Linux is a Linux distribution that uses a package manager named
`pacman`.  The scripts in this repository that use the name PKGBUILD
are shell scripts that describe how to build Midipix-related packages
for Arch Linux.  The PKGBUILD scripts are read and processed by the
`makepkg` utility that comes with `pacman`.

If you already know a little bit about `pacman` and `makepkg`, you can
just use the scripts in this repository to build all the packages.

If you are not familiar with `makepkg` or you just want to save some
time, I have provided a Ruby script called `megabuild.rb` that aims to
automate the building and installation of the packages as much as
possible.


How to use megabuild
====

1. Install Ruby:

        pacman -S ruby

2. Megabuild will place all of its build files in `$PWD/build`, `$PWD/build.log`, and `$PWD/pkg`, where `$PWD` is your current working directory.  So if you want those files to be somewhere special, you can change to that directory now.
3. Check the status of your system by running:

        ./megabuild.rb --status

4. This basically shows a list of packages, in the order that
megabuild wants to build them, and tells you if they are installed or
not.  Note that pacman packages have a cool feature where a package
with one name can declare that it provides the features of a package
with a different name.  This feature is controlled by the `provides`
array in the PKGBUILD scripts.  For example,
`x86_64-nt64-midipix-psxscl` provides `x86_64-nt64-midipix-psxstub`.
So if the megabuild status command tells you that the
`x86_64-nt64-midipix-psxstub` dependency is satisfied, it means that
either there is a package with that name installed or there is another
package that provides the same features.
5. Start building packages:

        ./megabuild.rb

6. If you get tired of having to enter your sudo password and answer
pacman prompts whener megabuild installs a package, then you can run:

        ./megabuild.rb --noconfirm

7. To avoid having to type your password for sudo, you can add the
following line to a file in `/etc/sudoers.d`:

        yourusername ALL = (root) NOPASSWD: /usr/bin/pacman


See also
===

* https://github.com/lalbornoz/midipix_build
