#!/bin/sh

# Copyright 2017 Steffen Moeller <moeller@debian.org>
# and Christian Dreihsig <christian.dreihsig@t-online.de>
#
# Distributed under terms of the GPL-2 or any later version.

set -e

if [ "-h" = "$1" -o "--help" = "$1" ]; then
cat <<EOHELP
Usage: $(basename $0) -h|--help - show this help
       $(basename $0) [file]    - compute and write wisdomf to file

The FFWT library offers the concept of wisdom files to cache the best
solutions for dissecting large series of data into serial invocations
of FFWT algorithmic variants.

This script is provided by the Einstein@Home community to support the
efficiency of the search for Binary Radio Pulsars.  On a lower level,
the wisdom file itself is created by the fftwf-wisdom tool as provided
by the ffwt library which takes between 6 and 120 hours to compute,
depending on the platform it is executed on.

EOHELP
exit
fi

DESTFILE="$1"
if [ -z "$1" ]; then
	DESTFILE=/tmp/wisdomf
fi


if [ -r "$DESTFILE" ]; then
	echo "E: File '$DESTFILE' is already existing."
	exit 1
fi

echo "I: Computing wisdom file for BRP4. This will take several hours if not days."
echo

fftwf-wisdom -n -v -o "$DESTFILE" rof12582912

echo "I: Wisdom file was computed successfully. Do"
echo "   sudo mkdir -p /etc/fftw"
echo "   sudo '$DESTFILE' /etc/fftw/wisdomf"