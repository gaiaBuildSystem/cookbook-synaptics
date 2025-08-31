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


print("Fetch syna-preboot ...", color=Color.WHITE, bg_color=BgColor.GREEN)

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

# clone it to the _BUILD_PATH
if not os.path.exists(f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-preboot"):
    os.chdir(f"{_BUILD_PATH}/tmp/{_MACHINE}")
    git clone @(meta["source"]) syna-preboot
else:
    os.chdir(f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-preboot")
    git fetch origin

os.chdir(f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-preboot")
git checkout @(meta["ref"]["linux/arm64"])

# make the assets acessible to the other repos
cp @(f"{_path}/{_MACHINE}/preboot.subimg") @(f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-preboot/preboot.subimg")
cp @(f"{_path}/{_MACHINE}/tee.subimg") @(f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-preboot/tee.subimg")
cp @(f"{_path}/{_MACHINE}/sm.bin") @(f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-preboot/sm.bin")
mkdir -p @(f"{_BUILD_PATH}/tmp/{_MACHINE}/output_sm/bin")
cp @(f"{_path}/{_MACHINE}/sm.bin") @(f"{_BUILD_PATH}/tmp/{_MACHINE}/su-boot/sm.bin")
cp @(f"{_path}/{_MACHINE}/sm.bin") @(f"{_BUILD_PATH}/tmp/{_MACHINE}/u-boot/sm.bin")


print("Fetch syna-preboot, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
