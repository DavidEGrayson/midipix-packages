This directory contains PKGBUILD scripts for Midipix-related Arch
Linux packages.

Using these scripts, you can build a working midipix toolchain
including GCC, Musl, pscsxl, and ntctty for Arch Linux.

Arch Linux is a Linux distribution that uses a package manager named
`pacman`.  The scripts in this directory that use the name PKGBUILD
are shell scripts that describe how to build Midipix-related packages
for Arch Linux.  The PKGBUILD scripts are read and processed by the
`makepkg` utility that comes with `pacman`.

If you already know a little bit about `pacman` and `makepkg`, you can
just use the scripts in this directory to build all the packages.

If you are not familiar with `makepkg` or you just want to save some
time, I have provided a Ruby script called `megabuild.rb` that will
automate the building and installation of the packages as much as
possible.

== How to use megabuild ==

1. Install Ruby:

        pacman -S ruby

2. Megabuild will place all of its build files in `$PWD/build`, `$PWD/build.log`, and `$PWD/pkg`, where `$PWD` is your current working directory.  So if you want those files to be somewhere special, you can change to that directory now.
3. Check the status of your system by running:

        ./megabuild.rb --status

4. This basically shows a list of packages, in the order that
Megabuild wants to build them, and tells you if they are installed or
not.  Note that pacman packages have a cool feature where a package
with one name can declare that it provides the features of a package
with a different name.  This feature is controlled by the `provides`
array in the PKGBUILD scripts.  For example,
`x86_64-nt64-midipix-psxscl` provides `x86_64-nt64-midipix-psxstub`.
So if the Megabuild status command tells you that the
`x86_64-nt64-midipix-psxstub` dependency is satisfied, it means that
either there is a package with that name installed or there is another
package that provides the same features.
5. Start building packages:

        ./megabuild.rb

6. If you get tired of having to enter your sudo password and answer
pacman prompts whener megabuild installs a package, then you can run:

        ./megabuild.rb --noconfirm
