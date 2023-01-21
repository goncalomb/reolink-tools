#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

[ -z "$1" ] && echo "usage: ${0##*/} <nvr-address>" && exit 1

rsync -a --info=name,progress root@$1:/proc/config.gz ./env-modules/
