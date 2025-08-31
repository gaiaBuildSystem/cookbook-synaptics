#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# Unfortunately the binary that synaptics delivers are only x86-64
# Therefore, we need to install the necessary libraries for x86-64

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$RAISE_SUBPROC_ERROR = True


import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("Install x86-64 libs for syna-tools ...", color=Color.WHITE, bg_color=BgColor.GREEN)

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


# add foreign arch
_HOST_ARCH = os.uname().machine
if _HOST_ARCH != "x86_64":
    sudo dpkg --add-architecture amd64
    sudo apt update
    sudo apt install -y \
        libc6:amd64


print("Install x86-64 libs for syna-tools, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
