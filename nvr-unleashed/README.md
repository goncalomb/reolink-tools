# nvr-unleashed

**This is currently a work-in-progress that completely disables the security of the NVR (SSH server with root access without password, fun). For now, use it for exploration only. Anything can change.**

Static binaries (see [./env-bin](./env-bin)): `strace`, `nmap`, `arp-scan`, `ip`, `dropbear` and `rsync`.

Kernel modules (see [./env-modules](./env-modules)): `bridge`.

Entrypoint: [./src/autoexec.sh](./src/autoexec.sh).

Extra scripts: [./src/bin](./src/bin).

## Building and Running

Requirements: Docker, GNU/Linux environment.

Docker containers are used to build the static binaries and kernel modules.

### First Build (partial)

Run `./build.sh`, this builds the static binaries. The first run is not a full build (no kernel modules).

Copy the contents of `./build` to a USB flash drive (important: MBR, FAT32, first partition).

Reboot the NVR, if everything goes right, after a few seconds you should hear a short beep, signaling that nvr-unleashed is loading, a second beep after a few seconds, followed by two beeps when it finishes loading (the first run can take some extra time, <1 min).

You should now have SSH access to the NVR (root without password):

    ssh root@your_nvr_ip

### Full Build

For creating a full build you should now fetch the kernel config from the NVR and save it to `./env-modules/config.gz`.

> Versions 2.X.X of the Reolink firmware don't appear to use a kernel build with built in configuration. See #1. This should be addressed in the future.

Fetching the configuration can be done just by running:

    ./ssh-fetch-ikconfig.sh your_nvr_ip

Alternatively, you can power off the NVR and check the contents of the drive, you will find a `config.gz` file, and copy it to `./env-modules/config.gz`.

You can now re-run the build `./build.sh` (it will include the kernel modules), copy the files to the drive, and reboot.

## Continuous Development

For easy development/testing, you can use the `./ssh-push.sh` script to push the local build directory to the NVR and re-run the `autoexec.sh`. This works after attaining SSH access with the first manual build.

After some local changes, testing is as easy as:

    ./build.sh && ./ssh-push.sh your_nvr_ip

## Patches

If necessary, patches can be created to modify the functionality of the binaries ([./env-bin/lib](./env-bin/lib)). Use the provided `./env-bin/patches.sh` script to manage the patches.

* `patches.sh apply`: apply current patches locally
* `patches.sh update`: save local changes (uncommitted changes) as patches (.patch files)
* `patches.sh restore`: restore local changes (discard uncommitted changes)

**Patches are automatically applied during the build (inside the Docker container).** The build will fail if the patches are applied locally and not restored before running the build.

The process to create/modify patches is: apply current patches, make necessary changes, update the patches, restore, and then build.

### Current Patches

[dropbear.patch](./env-bin/lib-patches/dropbear.patch):

* preserve PATH from host to client session to allow our custom bin location to be available even on non-login shells
