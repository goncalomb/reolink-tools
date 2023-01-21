#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

[ -z "$1" ] && echo "usage: ${0##*/} <nvr-address>" && exit 1
[ ! -d build ] && echo "'build' directory not found, run the build first" && exit 1

echo "sending files"
rsync -a --no-p --no-o --no-g --modify-window=2 --info=name,progress build/ root@$1:/mnt/usb/

echo "running 'autoexec.sh'"
ssh root@$1 /mnt/usb/autoexec.sh attached
