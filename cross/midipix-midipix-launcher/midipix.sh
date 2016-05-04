#!/bin/sh
#
# Launches Midipix from MSYS2, using MSYS2's mintty.
#
# This file is released to the public domain.

MIDIPIX_PATH=$(realpath $(dirname $0)/..)
cd "${MIDIPIX_PATH}/bin"
mintty -h always -e sh -c "
  set -o errexit
  stty raw -echo
  export \"PATH=${MIDIPIX_PATH}/bin:${MIDIPIX_PATH}/lib\"
  ./ntctty.exe -e midipix-start"

# was ./ntctty.exe -e bash --login -i

# TODO: chroot //${MIDIPIX_PATH#/}
