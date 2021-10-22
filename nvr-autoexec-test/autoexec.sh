#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

echo "[nvr-autoexec-test] hello"

( (
    sleep 10 # wait for boot

    echo "[nvr-autoexec-test] beep"
    # gpio0 is controls the built-in buzzer
    # but appears to be constantly be held low by the nvr firmware
    # we can still trigger it momentarily
    echo 1 >/sys/class/gpio/gpio0/value
    sleep 1
    echo 0 >/sys/class/gpio/gpio0/value
    sleep 1
    echo 1 >/sys/class/gpio/gpio0/value
    sleep 1
    echo 0 >/sys/class/gpio/gpio0/value
)&)
