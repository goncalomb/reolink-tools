#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

docker build bin-env -t nvr-build-bin-env
docker run --rm -it -v "$(pwd)/bin:/work/bin" nvr-build-bin-env:latest
