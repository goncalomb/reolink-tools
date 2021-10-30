#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

./build-bin.sh
./build-modules.sh
