#!/bin/bash

TTY=${1:-/dev/ttyUSB0}

{
sleep 1
echo "root" # username
sleep 1
echo "bc2020" # password
sleep 1
echo "reboot"
sleep 5
} | picocom -qb 115200 "$TTY"
