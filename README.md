# reolink-tools

## NVR

### AutoExec

As part of the boot sequence, the Reolink NVR will run a script called `autoexec.sh` on a USB flash drive. This script runs as root without any restriction and can be used to have full access to the embedded Linux system.

This process can be quite time sensitive, (the firmware waits 1 second to detect the drive).

### UART

The Reolink NVR has a UART header that can be used to have full access the Linux system (known root password).

### Prior Work

https://sirlagz.net/2017/03/02/poking-the-swann-nvr-7400/

https://edman007.com/article/Linux/Hacking-A-Reolink-NVR

### Hardware

Model | Hardware | UART
----- | -------- | ----
RLN8-410 | H3MB18 | ?
RLN8-410 | N2MB02 | ?
RLN8-410 | N3MB01 | ?
RLN8-410-E | H3MB16 | yes
RLN16-410 | H3MB18 | yes


### Firmware

Model  | Firmware Version (app) | root user | root password
------ | ---------------------- | --------- | -------------
RLN16-410 | v3.0.0.110_20122648 | root | bc2020

## Tools

### nvr-unleashed

The nvr-unleashed project is currently a proof-of-concept and ongoing attempt to extend the Reolink NVR features by "soft-modding" using an external USB flash drive (without patching the oem firmware or any other permanent modification).

Current features:

* Static builds of some useful tools: dropbear, strace, nmap, iproute2...
* Kernel config for building extra modules
* Auto configured SSH server (dropbear)
* Root password bypass

Future features:

* Modularize the code (features aka addons)
* Feature gates
* More tools (as static binaries)
* More kernel modules
* Support fot SSH authorized_keys (~/.ssh/authorized_keys)
* HTTP API extensions
* Network interface bridging
* Netfilter support
* PoE and VLAN controls (unknown support, requires more hardware analysis)
* Buzzer control

More info on [nvr-unleashed/](nvr-unleashed/).

## nvr-autoexec-test

Sample script to test `autoexec.sh`, copy `./nvr-autoexec-test/autoexec.sh` to a USB flash drive (MBR, FAT32, first partition), plug it to the NVR and reboot, the built-in buzzer should trigger twice during boot as confirmation.

## nvr-debug-scripts

File | Description
---- | -----------
uart-autoexec.sh | Manually trigger `autoexec.sh` using the UART tty (useful if it fails to trigger automatically).
uart-reboot.sh | Reboot NVR through the UART tty.
