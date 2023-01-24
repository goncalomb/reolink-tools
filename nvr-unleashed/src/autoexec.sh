#!/bin/sh

# this is the entrypoint for nvr-unleashed, it runs on the nvr during boot

# it is made to be idempotent, you can run it multiple times (even after boot)
# to re-copy the binaries and modules form the usb drive, without side effects
# this can be useful during development/testing over ssh (no need to reboot)
# but it does not teardown/remount the entire nvr-unleashed, so a full reboot
# is still necessary specially if testing any changes to this file

# during boot the buzzer should beep a total of 3 times
# beep... beep beep... (2 beeps at the end)

# can be called with a argument 'attached' to speed up the process (no sleep
# or detached subshell), it beeps only twice, this can be used after boot

# during boot it is called with no arguments and the detached subshell is
# required to let the boot process of the nvr continue while nvr-unleashed
# is initializing

set -e

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

# right now the boot sequence is still in the beginning, even the gpio is
# not configured correctly so we can't even beep, we need to detach and wait

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
[ "$1" != "attached" ] && beep

# remount usb
if ! is_mount_point /mnt/usb ; then
    echo "[nvr-unleashed] remounting"
    mount -t vfat /dev/usb/usbhd1 /mnt/usb
else
    echo "[nvr-unleashed] '/mnt/usb' already mounted"
fi

# change directory late to avoid locking the usb device and prevent unmounting
cd -- "$(dirname -- "$0")"

# create unleashed dir
if ! is_mount_point "$UNLEASHED_LOCATION"; then
    mkdir -p "$UNLEASHED_LOCATION"
    mount -t tmpfs -o size=64M tmpfs "$UNLEASHED_LOCATION"
else
    echo "[nvr-unleashed] '$UNLEASHED_LOCATION' already exists"
fi

# copy binaries and kernel modules
echo "[nvr-unleashed] copying binaries and kernel modules"
if command -v rsync >/dev/null; then
    # use rsync if available for incremental copy
    # this should only happen if 'autoexec.sh' is run after boot,
    # the firmware does not include rsync
    # using '--inplace' because memory is limited (tmpfs)
    # fail back to cp, 'rsync --inplace' will fail to replace itself if
    # pushing a new rsync binary
    rsync -a --inplace bin "$UNLEASHED_LOCATION" || cp -a bin "$UNLEASHED_LOCATION"
    rsync -a --inplace modules "$UNLEASHED_LOCATION" || cp -a modules "$UNLEASHED_LOCATION"
else
    cp -a bin "$UNLEASHED_LOCATION"
    cp -a modules "$UNLEASHED_LOCATION"
fi
chmod +x "$UNLEASHED_LOCATION/bin"/*

# dump ikconfig (in-kernel config)
if [ -f "/proc/config.gz" ]; then
    cp /proc/config.gz config.gz
else
    echo "[nvr-unleashed] '/proc/config.gz' kernel config not found"
fi

# change directory
cd "$UNLEASHED_LOCATION"

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
# we inject the kernel modules by hijacking a directory under '/lib/modules/'
# using a bind mount to a new directory with our modules
INJECTION_POINT="/lib/modules/$(uname -r)/kernel" # alternative to .../extra
if ! is_mount_point "$INJECTION_POINT"; then
    if [ -z "$(ls -A "$INJECTION_POINT")" ]; then
        # injection point is empty, just mount
        echo "[nvr-unleashed] injecting kernel modules"
        mount -o bind modules "$INJECTION_POINT"
    else
        # injection point contains other kernel modules, copy and mount
        echo "[nvr-unleashed] injecting kernel modules, with bypass"
        cp -a "$INJECTION_POINT" modules_injection
        mkdir -p modules_injection/unleashed
        mount -o bind modules_injection "$INJECTION_POINT"
        mount -o bind modules "$INJECTION_POINT/unleashed"
    fi
    depmod
else
    echo "[nvr-unleashed] reloading kernel modules"
    depmod
fi

# beep
beep ; beep

)&

# wait, don't detach
[ "$1" == "attached" ] && wait

)
