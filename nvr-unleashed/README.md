# nvr-unleashed

**This is currently a work-in-progress that completely disables the security of the NVR (SSH server with root access without password, fun). For now, use for exploration only.**

## Building and Running

Requirements: Docker, GNU/Linux environment.

Docker containers are used to build the static binaries and kernel modules.

Run `./build.sh`, this builds the static binaries required to run nvr-unleashed. The first run is not a full build (no kernel modules).

Copy the contents of `./build` to a USB flash drive (important: MBR, FAT32, first partition).

Reboot the NVR, if everything goes right, after a few seconds you should hear the short beep, signaling that nvr-unleashed is loading, followed by two beeps when it finishes loading (the first time it can take some extra time, <1 min).

You should now have SSH access to the NVR (root without password):

    ssh root@your_nvr_ip

For creating a full build you should now fetch the kernel config from the NVR and save it to `./env-modules/.config`, i.e:

    ssh root@your_nvr_ip cat /proc/config.gz | zcat > ./nvr-unleashed/env-modules/.config

You can now re-run the build `./build.sh` (will include the kernel modules), copy de files to the drive, and reboot.
