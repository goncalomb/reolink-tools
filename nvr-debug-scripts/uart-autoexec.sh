#!/bin/bash

TTY=${1:-/dev/ttyUSB0}

{
sleep 1
echo "root" # username
sleep 1
echo "bc2020" # password
sleep 1
cat <<EOF
mount -t vfat /dev/usb/usbhd1 /mnt/usb
chmod +x /mnt/usb/autoexec.sh
/mnt/usb/autoexec.sh
umount -f /mnt/usb
ifconfig
EOF
sleep 10
} | picocom -qb 115200 "$TTY"
