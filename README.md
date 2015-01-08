nimrtlsdr
=========

A Nim wrapper for librtlsdr (a driver for Realtek RTL2832U based SDR's)


[![Godoc reference](https://godoc.org/github.com/jpoirier/gortlsdr?status.svg)](https://godoc.org/github.com/jpoirier/gortlsdr)

# Description

gnimtlsdr is a simple Nim interface to devices supported by the RTL-SDR project, which turns certain USB DVB-T dongles
employing the Realtek RTL2832U chipset into a low-cost, general purpose software-defined radio receiver. It wraps all
the functions in the [librtlsdr library](http://sdr.osmocom.org/trac/wiki/rtl-sdr) (including asynchronous read support).

Supported Platforms:
* Linux
* OS X
* Windows


# Installation

## Dependencies
* [Nim tools](https://nim-lang.org)
* [librtlsdr] (http://sdr.osmocom.org/trac/wiki/rtl-sdr) - builds dated after 5/5/12
* [libusb] (https://www.libusb.org)
* [git] (https://git-scm.com)


## Usage
All functions in librtlsdr are accessible from the nimrtlsdr package:

	$ nimble install git://github.com/jpoirier/nimrtlsdr

## Example
See the examples/rtlsdr_eample.nim file:

	$ cd examples
    $ $ nim c rtlsdr_example.nim

## Windows
If you don't want to build the librtlsdr and libusb dependencies from source you can use the librtlsdr pre-built package,
which includes libusb, but you're restricted to building a 32-bit gortlsdr library.

Building nimrtlsdr on Windows:
* Download and install [git](http://git-scm.com).
* Download and install the [Nim tools](http://nim-lang.org/download.html).
* Download the pre-built [rtl-sdr library](http://sdr.osmocom.org/trac/attachment/wiki/rtl-sdr/RelWithDebInfo.zip) and unzip
  it, e.g. to your user folder. Note the path to the header and *.dll files are in the x32 folder.
* Download nimrtlsdr, but don't install the package:

	$ git clone git@github.com:jpoirier/nimrtlsdr.git

* Set CFLAGS and LDFLAGS in rtlsdr.go. Open the rtlsdr.go file in an editor, it'll be in go-pkgs\src\github.com\jpoirier\gortlsdr,
  and set the following two windows specific flags shown below, but with the correct paths from your system. CFLAGS points to
  the header files and LDFLAGS to the *.dll files:

          cgo windows CFLAGS: -IC:/Users/jpoirier/rtlsdr
          cgo windows LDFLAGS: -lrtlsdr -LC:/Users/jpoirier/rtlsdr/x32

* Build gortlsdr:

          go install github.com/jpoirier/gortlsdr

* Insert the DVB-T/DAB/FM dongle into a USB port, open a shell window in nimble\pkgs\src\github.com\jpoirier\gortlsdr and run
  the example program: go run rtlsdr_example.go. Note, the pre-built rtl-sdr package contains several test executables as well.


# Credit
* [pyrtlsdr](https://github.com/roger-/pyrtlsdr) for the great read-me description, which I copied.
* [osmoconSDR] (http://sdr.osmocom.org/trac/wiki/rtl-sdr) for the rtl-sdr library.
* [Antti Palosaari] (http://thread.gmane.org/gmane.linux.drivers.video-input-infrastructure/44461/focus=44461) for sharing!

# Todo


-joe
