#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

mkdir -p bin

echo "building local binaries"

find src/go -name *.go | while IFS= read -r ENTRY; do
    echo "building $ENTRY"
    GOOS=linux GOARCH=$ARCH go build -o bin "$ENTRY"
done

echo "building other binaries"

./patches.sh apply

if [ ! -f "bin/strace" ]; then (
    # strace
    cd lib/strace
    # build
    export LDFLAGS="-static"
    ./bootstrap
    ./configure --host=arm
    make -j8
    # copy binaries
    cp -at ../../bin src/strace
) fi

if [ ! -f "bin/nmap" ]; then (
    # nmap
    cd lib/nmap
    # build
    export LDFLAGS="-static"
    ./configure --host=arm
    make -j8
    # copy binaries
    cp -at ../../bin nmap ncat/ncat nping/nping
) fi

if [ ! -f "bin/arp-scan" ]; then (
    # libpcap
    (
        cd lib/libpcap
        ./configure --host=arm-linux
        make -j8
    )
    # arp-scan
    cd lib/arp-scan
    # build
    export CFLAGS="-I/work/lib/libpcap"
    export LDFLAGS="-L/work/lib/libpcap -static"
    autoreconf --install
    ./configure --host=arm-linux
    make -j8
    # copy binaries
    cp -at ../../bin arp-scan
) fi

if [ ! -f "bin/ip" ]; then (
    # iproute2
    cd lib/iproute2
    # build
    export LDFLAGS="-static"
    ./configure
    make -j8
    # copy binaries
    cp -at ../../bin ip/ip bridge/bridge
) fi

if [ ! -f "bin/dropbear" ]; then (
    # dropbear
    cd lib/dropbear
    # build
    ./configure --host=arm --enable-static --disable-zlib
    make -j8
    make -j8 scp
    # copy binaries
    cp -at ../../bin dropbear dropbearkey scp
) fi

if [ ! -f "bin/rsync" ]; then (
    # rsync
    cd lib/rsync
    # build
    export LDFLAGS="-static"
    ./configure --host=arm --disable-md2man --disable-openssl --disable-xxhash --disable-zstd --disable-lz4
    make -j8
    # copy binaries
    cp -at ../../bin rsync
) fi

echo
echo "result"
echo

file bin/*
