# reolink-tools

## nvr-autoexec-test

As part of the boot sequence, the Reolink NVR will run a script called `autoexec.sh` on a USB flash drive (1st partition, FAT32).

This script runs as root without any restriction and can be used to have full access to the embedded Linux system.

You can test this by using the script `nvr-autoexec-test/autoexec.sh`, the built-in buzzer should trigger twice during boot as confirmation.
