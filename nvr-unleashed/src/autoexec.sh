#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

UNLEASHED_LOCATION="/mnt/tmp/nvr-unleashed"

beep() {
    echo 1 >/sys/class/gpio/gpio0/value ; sleep 0.2
    echo 0 >/sys/class/gpio/gpio0/value ; sleep 0.8
}

is_mount_point() {
    # weird way to detect mount points, fails with /
    mount_point() {
        df -- "$1" | tail -n1 | tr -s ' ' | cut -d ' ' -f6
    }
    # is the path in same device as the parent directory?
    [ -e "$1" ] && [ "$(mount_point "$1")" != "$(mount_point "$(dirname -- "$1")")" ]
}

echo "[nvr-unleashed] hello"

# beep
beep

# create unleashed dir
if ! is_mount_point "$UNLEASHED_LOCATION"; then
    mkdir -p "$UNLEASHED_LOCATION"
    mount -t tmpfs -o size=64M tmpfs "$UNLEASHED_LOCATION"
else
    echo "[nvr-unleashed] '$UNLEASHED_LOCATION' already exists"
fi

# copy binaries
echo "[nvr-unleashed] copying binaries"
cp -a bin "$UNLEASHED_LOCATION"
cp -a modules "$UNLEASHED_LOCATION"
chmod +x "$UNLEASHED_LOCATION/bin"/*

# dump kernel config (.config)
if [ -f "/proc/config.gz" ]; then
    cp /proc/config.gz config.gz
else
    echo "[nvr-unleashed] '/proc/config.gz' kernel config not found"
fi

# change directory early to release the usb device and allow unmounting
cd "$UNLEASHED_LOCATION"

# start detached subshell to continue later
( (

# the nvr unmounts '/mnt/usb' right after running 'autoexec.sh'
# so we create a detached subshell, let it unmount and remount after
# see '/etc/init.d/S90StartSuvr'
# don't detach if called with 'attached'

if [ "$1" != "attached" ]; then
    echo "[nvr-unleashed] waiting 5 seconds before remounting"
    sleep 5
fi

# beep
beep

# mount usb
if ! is_mount_point /mnt/usb ; then
    echo "[nvr-unleashed] remounting"
    mount -t vfat /dev/usb/usbhd1 /mnt/usb
else
    echo "[nvr-unleashed] already mounted"
fi

# mount root tmpfs
if ! is_mount_point /root ; then
    mount -t tmpfs -o size=2M tmpfs /root
fi

# bypass root password
if ! is_mount_point /etc/passwd ; then
    echo "root::0:0:root:/root:/bin/sh" >"$UNLEASHED_LOCATION/passwd"
    mount -o bind "$UNLEASHED_LOCATION/passwd" /etc/passwd
fi

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

if [ ! -f dropbear_rsa_host_key ]; then
    cp /mnt/usb/dropbear_rsa_host_key .
    # start dropbear
    echo "[nvr-unleashed] starting dropbear"
    dropbear -BE -r dropbear_rsa_host_key
fi

# prepare modules
# we inject the kernel modules by hijacking the 'extra' directory using a
# bind mount to a new directory with the extra modules
if [ ! -d modules_extra ]; then
    echo "[nvr-unleashed] injecting kernel modules"
    cp -r "/lib/modules/$(uname -r)/extra" .
    mv extra modules_extra
    mv modules modules_extra/unleashed
    mount -o bind modules_extra "/lib/modules/$(uname -r)/extra"
    depmod
elif [ -d modules ]; then
    echo "[nvr-unleashed] reloading kernel modules"
    rm -rf modules_extra/unleashed
    mv modules modules_extra/unleashed
    depmod
fi

# beep
beep ; beep

)&

# wait, don't detach
[ "$1" == "attached" ] && wait

)
