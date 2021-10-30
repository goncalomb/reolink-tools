#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

mkdir -p bin

if [ ! -f "bin/strace" ]; then (
    # strace
    [ -d strace ] || git clone --depth=1 https://github.com/strace/strace.git
    cd strace
    # build
    export LDFLAGS="-static"
    ./bootstrap
    ./configure --host=arm
    make -j8
    # copy binaries
    cp -at ../bin src/strace
) fi

if [ ! -f "bin/ip" ]; then (
    # iproute2
    [ -d iproute2 ] || git clone --depth=1 https://github.com/shemminger/iproute2.git
    cd iproute2
    # build
    export LDFLAGS="-static"
    ./configure
    make -j8
    # copy binaries
    cp -at ../bin ip/ip bridge/bridge
) fi

if [ ! -f "bin/dropbear" ]; then (
    # dropbear
    [ -d dropbear ] || git clone --depth=1 https://github.com/mkj/dropbear.git
    cd dropbear
    # patch to allow custom user shells
    sed -i -e "s/setusershell()/goto goodshell/g" svr-auth.c
    # build
    ./configure --host=arm --enable-static --disable-zlib
    make -j8
    make -j8 scp
    # copy binaries
    cp -at ../bin dropbear dropbearkey scp
) fi

echo
echo "result"
echo

file bin/*
