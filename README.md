Scripts for building midipix packages from Arch Linux

To use these scripts, you must be on a machine with makepkg and you musthave a x86_64-nt64-midipix-gcc toolchain on your PATH.

To compile a package, go into its directory and run:

   makepkg --config ../makepkg_midipix64.conf -Lf


I haven't quite figured out how to copy/install the packages to Windows though. For now, just take the files you need from the `pkg` directory and copy them to Windows.