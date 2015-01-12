nimrtlsdr
=========

A [Nim](http://nim-lang.org) wrapper for librtlsdr (a driver for Realtek RTL2832U based SDR's)



# Description

nimtlsdr is a simple Nim interface to devices supported by the RTL-SDR project, which turns certain USB DVB-T dongles
employing the Realtek RTL2832U chipset into a low-cost, general purpose software-defined radio receiver. It wraps all
the functions in the [librtlsdr library](http://sdr.osmocom.org/trac/wiki/rtl-sdr) (including asynchronous read support).

Supported Platforms:
* Linux
* OS X
* Windows


# Installation

## Dependencies
* [Nim compiler](http://nim-lang.org)
* [librtlsdr] (http://sdr.osmocom.org/trac/wiki/rtl-sdr) - builds dated after 5/5/12
* [libusb] (https://www.libusb.org)
* [git] (https://git-scm.com)


## Building nimrtlsdr
* Download and install [git](http://git-scm.com).
* Download and install the [Nim tools](http://nim-lang.org/download.html).
* Download the pre-built [rtl-sdr library](http://sdr.osmocom.org/trac/attachment/wiki/rtl-sdr/RelWithDebInfo.zip) and install.
* Install the nimrtlsdr package:

  Using nimble:

  $ nimble install git://github.com/jpoirier/nimrtlsdr

  $ git clone git@github.com:jpoirier/nimrtlsdr.git

  Go to the nimrtlsdr/examples folder and...

  ...if you installed using nimble:

    $ nim c rtlsdr_example.nim

  ...if you didn't install using nimble you need to provide the path to the nimrtlsdr library source:

    $ nim c --path:../src rtlsdr_example.nim

* Insert the DVB-T/DAB/FM dongle into a USB port and run the rtlsdr_example example program.

  $ ./rtlsdr_example

# Credit
* [pyrtlsdr](https://github.com/roger-/pyrtlsdr) for the great read-me description, which I copied.
* [osmoconSDR] (http://sdr.osmocom.org/trac/wiki/rtl-sdr) for the rtl-sdr library.
* [Antti Palosaari] (http://thread.gmane.org/gmane.linux.drivers.video-input-infrastructure/44461/focus=44461) for sharing!



-joe
