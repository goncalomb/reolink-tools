#!/bin/sh

set -e
cd -- "$(dirname -- "$0")"

mkdir -p modules

if [ -z "$(ls -A modules)" ]; then (
    # clone kernel source
    git clone --depth=1 --branch=v4.9.44 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
    cd linux-stable

    zcat ../config.gz > .config

    # tweak config to enable some modules
    sed -i \
        -e "s/.*CONFIG_BRIDGE.*/CONFIG_BRIDGE=m/g" \
        -e "/.*CONFIG_NETFILTER.*/d" \
        .config

    # patch module vermagic to match the one used by the oem nvr kernel
    # i couldn't find a valid kernel config with ARM_PATCH_PHYS_VIRT disabled
    # it would always default to 'y' (yes)
    # XXX: find a better way to do this
    sed -i -e "s/p2v8 //g" arch/arm/include/asm/module.h
    # nuking git repo because uncommitted changes also affect vermagic value
    rm -rf .git

    # rebuild config with default values for all remaining parameters
    yes "" | make oldconfig
    # build modules
    make modules

    # collect .ko files
    find | grep "\.ko$" | xargs cp -t ../modules/
) fi

echo
echo "result"
echo

file modules/*
