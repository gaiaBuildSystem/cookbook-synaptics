#!/bin/busybox sh

if [[ $root == LABEL:* ]]; then
    _label="${root#*:}"
    echo "[initramfs] searching for root partition astra"

    # TODO: for now we have this hard coded
    mount -t ext4 /dev/mmcblk0p8 /mnt/root
    mount -t proc proc /mnt/root/proc
    mount -t sysfs sys /mnt/root/sys
    mount --rbind dev /mnt/root/dev
    mount --make-rslave /mnt/root/dev

    echo "[initramfs] root partition /dev/mmbclk0p8 mounted"

else
    echo "[initramfs] root partition argument not found"
    exit 69
fi
