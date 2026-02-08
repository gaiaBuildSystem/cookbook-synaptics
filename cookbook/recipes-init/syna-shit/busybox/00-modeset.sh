#!/bin/busybox sh

if [[ $MACHINE == sl2619 ]]; then
    echo "[initramfs] Synaptics modeset"
    /bin/drmset 0

    # let's settle
    sleep 4

else
    echo "[initramfs] Synaptics modeset not needed"
    exit 0

fi
