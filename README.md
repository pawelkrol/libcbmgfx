libcbmgfx
=========

`libcbmgfx` is a simple thread-safe Commodore 64 graphics
library with a built-in support for the most common CBM
file format specifications, entirely written in [x86-64]
Assembly language. It supports reading, rendering,
converting, and writing picture data from/to miscellaneous
CBM image data formats.

## Version

Version 1.1.0 (2025-09-11)

## Prerequisites

Install build and runtime libraries:

    $ sudo dnf install -y libpng libpng-devel

Install test libraries (optional, if you want to run tests):

    $ sudo dnf install -y boost-devel doctest-devel

Install packaging software (optional, if you want to build
an RPM package):

    $ sudo dnf install -y rpmdevtools rpmlint
    $ rpmdev-setuptree

## Installation

Clone the repository:

    $ git clone https://github.com/pawelkrol/libcbmgfx.git

Compile and install the library:

    $ cd libcbmgfx
    $ make -j16
    $ make check
    $ sudo make install

Uninstall files from the system:

    $ sudo make uninstall

Distribute software as an RPM package:

    $ make dist

Remove all compiled files:

    $ make distclean

## How to use it?

Please see [HOWTO] for the detailed instructions on using
the C/C++ API.

## Copyright and Licence

Copyright (C) 2025 by Pawel Krol.

This software is distributed under the terms of the MIT
license. See [LICENSE] for more information.


[x86-64]: https://en.wikipedia.org/wiki/X86-64
[HOWTO]: https://github.com/pawelkrol/libcbmgfx/blob/master/HOWTO.md
[LICENSE]: https://github.com/pawelkrol/libcbmgfx/blob/master/LICENSE.md
