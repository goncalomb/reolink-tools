#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

UNLEASHED_LOCATION="/tmp/nvr-unleashed"

beep() {
    echo 1 >/sys/class/gpio/gpio0/value ; sleep 0.2
    echo 0 >/sys/class/gpio/gpio0/value ; sleep 0.8
}

echo "[nvr-unleashed] hello"

# copy binaries
mkdir -p "$UNLEASHED_LOCATION/bin"
cp -a bin/* "$UNLEASHED_LOCATION/bin"
chmod +x "$UNLEASHED_LOCATION/bin"/*

# change directory early to release the usb device and allow unmounting
cd "$UNLEASHED_LOCATION"

# start detached subshell to continue later
( (

echo "[nvr-unleashed] waiting 5 seconds before remounting"
sleep 5

# beep
beep

# mount usb and root tmpfs
echo "[nvr-unleashed] remounting"
mount -t vfat /dev/usb/usbhd1 /mnt/usb
mount -t tmpfs -o size=2M tmpfs /root

# bypass root password
echo "root::0:0:root:/root:/bin/sh" >"$UNLEASHED_LOCATION/passwd"
mount -o bind "$UNLEASHED_LOCATION/passwd" /etc/passwd

# set path
export PATH="$PATH:$UNLEASHED_LOCATION/bin"
echo "PATH="\$PATH:$UNLEASHED_LOCATION/bin"" >/root/.profile

# generate dropbear key
if [ ! -f /mnt/usb/dropbear_rsa_host_key ]; then
    echo "[nvr-unleashed] generating dropbear key"
    dropbearkey -t rsa -f /mnt/usb/dropbear_rsa_host_key
fi
cp /mnt/usb/dropbear_rsa_host_key .

# start dropbear
echo "[nvr-unleashed] starting dropbear"
dropbear -BE -r dropbear_rsa_host_key

# beep
beep ; beep

)&)
