#!/bin/sh

set -e

# Firefox launcher containing a Profile migration helper for
# temporary profiles used during alpha and beta phases.

# Authors:
#  Alexander Sack <asac@jwsdot.com>
#  Fabien Tassin <fta@sofaraway.org>
#  Steve Langasek <steve.langasek@canonical.com>
#  Chris Coulson <chris.coulson@canonical.com>
# License: GPLv2 or later

MOZ_LIBDIR=/usr/lib/firefox
MOZ_APP_LAUNCHER=`which $0`
MOZ_APP_NAME=firefox
MOZ_DEFAULT_PROFILEDIR=/usr/share/hotelos/firefox
MOZ_PROFILEDIR=/usr/share/hotelos/firefox

export MOZ_APP_LAUNCHER

while [ ! -x $MOZ_LIBDIR/$MOZ_APP_NAME ] ; do
    if [ -L "$MOZ_APP_LAUNCHER" ] ; then
        MOZ_APP_LAUNCHER=`readlink -f $MOZ_APP_LAUNCHER`
        MOZ_LIBDIR=`dirname $MOZ_APP_LAUNCHER`
    else
        echo "Can't find $MOZ_LIBDIR/$MOZ_APP_NAME"
        exit 1
    fi
done

usage () {
    $MOZ_LIBDIR/$MOZ_APP_NAME -h | sed -e 's,/.*/,,'
    echo
    echo "      -g or --debug          Start within debugger"
    echo "      -d or --debugger       Specify debugger to start with (eg, gdb or valgrind)"
    echo "      -a or --debugger-args  Specify arguments for debugger"
}

moz_debug=0
moz_debugger_args=""
moz_debugger="gdb"

while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help )
            usage
            exit 0
            ;;
        -g | --debug )
            moz_debug=1
            shift
            ;;
        -d | --debugger)
            moz_debugger=$2;
            if [ "${moz_debugger}" != "" ]; then
	      shift 2
            else
              echo "-d requires an argument"
              exit 1
            fi
            ;;
        -a | --debugger-args )
            moz_debugger_args=$2;
            if [ "${moz_debugger_args}" != "" ] ; then
                shift 2
            else
                echo "-a requires an argument"
                exit 1
            fi
            ;;
        -- ) # Stop option processing
            shift
            break
            ;;
        * )
            break
            ;;
    esac
done


if [ $moz_debug -eq 1 ] ; then
    case $moz_debugger in
        memcheck)
            debugger="valgrind"
            ;;
        *)
            debugger=$moz_debugger
            ;;
    esac

    debugger=`which $debugger`
    if [ ! -x $debugger ] ; then
        echo "Invalid debugger"
        exit 1
    fi

    case `basename $moz_debugger` in
        gdb)
            exec $debugger $moz_debugger_args --args $MOZ_LIBDIR/$MOZ_APP_NAME "$@"
            ;;
        memcheck)
            echo "$MOZ_APP_NAME has not been compiled with valgrind support"
            exit 1
            ;;
        *)
            exec $debugger $moz_debugger_args $MOZ_LIBDIR/$MOZ_APP_NAME "$@"
            ;;
    esac
else
    exec $MOZ_LIBDIR/$MOZ_APP_NAME "$@"
fi
