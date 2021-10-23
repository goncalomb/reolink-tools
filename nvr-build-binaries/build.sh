#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

docker build build-env -t build-env
docker run --rm -it -v "$(pwd)/bin:/work/bin" build-env:latest
