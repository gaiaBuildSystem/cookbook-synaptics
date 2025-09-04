#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$RAISE_SUBPROC_ERROR = True


import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("Copying linux syna-firmware ...", color=Color.WHITE, bg_color=BgColor.GREEN)

# get the common variables
_ARCH = os.environ.get('ARCH')
_MACHINE = os.environ.get('MACHINE')
_MAX_IMG_SIZE = os.environ.get('MAX_IMG_SIZE')
_BUILD_PATH = os.environ.get('BUILD_PATH')
_DISTRO_MAJOR = os.environ.get('DISTRO_MAJOR')
_DISTRO_MINOR = os.environ.get('DISTRO_MINOR')
_DISTRO_PATCH = os.environ.get('DISTRO_PATCH')
_USER_PASSWD = os.environ.get('USER_PASSWD')

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT
_LINUX_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/linux/firmware"


# copy the linux/firmware/* to /lib/firmware
sudo mkdir -p @(_IMAGE_MNT_ROOT)/lib/firmware
sudo cp -r @(_LINUX_PATH)/* @(_IMAGE_MNT_ROOT)/lib/firmware

# mv the vendor content to the root
sudo cp -r @(_IMAGE_MNT_ROOT)/lib/firmware/bcm/* @(_IMAGE_MNT_ROOT)/lib/firmware
sudo cp -r @(_IMAGE_MNT_ROOT)/lib/firmware/mrvl/* @(_IMAGE_MNT_ROOT)/lib/firmware

sudo rm -rf @(_IMAGE_MNT_ROOT)/lib/firmware/mrvl
sudo rm -rf @(_IMAGE_MNT_ROOT)/lib/firmware/bcm


print("Copying linux syna-firmware, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
