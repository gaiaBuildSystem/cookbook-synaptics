#!/bin/bash

set -e

# Align bootloader.subimg to 512B
bootloader_subimg_size=`stat -c %s ${_DEPLOY_DIR}/bootloader_nopreload.subimg`
bootloader_append_size=`expr 512 - ${bootloader_subimg_size} % 512`

cp ${_DEPLOY_DIR}/bootloader_nopreload.subimg ${_DEPLOY_DIR}/bootloader.subimg

if [ ${bootloader_append_size} -lt 512 ]; then
    dd if=/dev/zero of=${_DEPLOY_DIR}/bootloader.subimg bs=1 seek=${bootloader_subimg_size} count=${bootloader_append_size} conv=notrunc
fi

if [ -f ${_DEPLOY_DIR}/preload_ta.subimg ];then
    cat ${_DEPLOY_DIR}/preload_ta.subimg >> ${_DEPLOY_DIR}/bootloader.subimg
fi

mv ${_DEPLOY_DIR}/bootloader.subimg ${_DEPLOY_DIR}/bl.subimg
gzip -f ${_DEPLOY_DIR}/bl.subimg
