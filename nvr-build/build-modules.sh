#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

docker build modules-env -t nvr-build-modules-env
docker run --rm -it -v "$(pwd)/modules:/work/modules" nvr-build-modules-env:latest
