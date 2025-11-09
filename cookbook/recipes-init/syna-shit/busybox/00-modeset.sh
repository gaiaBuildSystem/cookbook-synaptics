#!/bin/busybox sh

if [[ $MACHINE == sl2619 ]]; then
    echo "[initramfs] Synaptics modeset"
    /usr/bin/fbset -g 1920 1080 1920 1080 32

else
    echo "[initramfs] Synaptics modeset not needed"
    exit 69

fi
