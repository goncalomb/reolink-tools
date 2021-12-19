#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

mkdir -p build build/bin build/modules

# copy from src
cp -a src/autoexec.sh build/
cp -at build/bin/ src/bin/*

# build binaries and modules
build_env() {
    docker build env-$1 -t nvr-unleashed-env-$1
    docker run --rm -it -v "$(pwd)/build/$1:/work/$1" nvr-unleashed-env-$1:latest
}

build_env bin
if [ -f env-modules/config.gz ]; then
    build_env modules
else
    echo
    echo "config.gz not found (will not compile modules)"
fi

echo
echo "all binaries and modules"
echo

file build/bin/* build/modules/*

echo
echo "build done"
echo "now copy the contents of the build folder pen drive for the nvr"
