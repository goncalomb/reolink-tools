#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

UNLEASHED_LOCATION="/tmp/nvr-unleashed"

beep() {
    echo 1 >/sys/class/gpio/gpio0/value ; sleep 0.2
    echo 0 >/sys/class/gpio/gpio0/value ; sleep 0.8
}

echo "[nvr-unleashed] hello"

# create unleashed dir
mkdir -p "$UNLEASHED_LOCATION"
mount -t tmpfs -o size=64M tmpfs "$UNLEASHED_LOCATION"

# copy binaries
cp -a bin "$UNLEASHED_LOCATION"
cp -a modules "$UNLEASHED_LOCATION"
chmod +x "$UNLEASHED_LOCATION/bin"/*

# dump kernel config (.config)
cp /proc/config.gz config.gz

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
export PATH="$UNLEASHED_LOCATION/bin:$PATH"
echo "PATH="$UNLEASHED_LOCATION/bin:\$PATH"" >/root/.profile

# replace root shell with a bash script that populates the PATH
# this is necessary for scp to work because it uses a non-login shell
cat >"$UNLEASHED_LOCATION/sh" <<EOF
#!/bin/sh
export PATH="$UNLEASHED_LOCATION/bin:\$PATH"
# detect if stdin is a tty, if that's the case, start login shell
# this is not entirely correct but apparently we can't detect the '-' on the
# zeroth argument of the script (login shell)
# TODO: this should probably be replaced by a small c program
L=-l
[ -t 0 ] || L=
exec /bin/sh \$L "\$@"
EOF
chmod +x "$UNLEASHED_LOCATION/sh"
echo "root::0:0:root:/root:$UNLEASHED_LOCATION/sh" >"$UNLEASHED_LOCATION/passwd"

# generate dropbear key
if [ ! -f /mnt/usb/dropbear_rsa_host_key ]; then
    echo "[nvr-unleashed] generating dropbear key"
    dropbearkey -t rsa -f /mnt/usb/dropbear_rsa_host_key
fi
cp /mnt/usb/dropbear_rsa_host_key .

# start dropbear
echo "[nvr-unleashed] starting dropbear"
dropbear -BE -r dropbear_rsa_host_key

# prepare modules
cp -r "/lib/modules/$(uname -r)/extra" .
mv extra modules_extra
mv modules modules_extra/unleashed
mount -o bind modules_extra "/lib/modules/$(uname -r)/extra"
depmod

# beep
beep ; beep

)&)
