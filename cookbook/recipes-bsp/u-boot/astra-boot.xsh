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


print("Deploying astra u-boot artifacts ...", color=Color.WHITE, bg_color=BgColor.GREEN)

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
_DEPLOY_DIR = f"{_BUILD_PATH}/tmp/{_MACHINE}/deploy"
_REPO_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/u-boot"
_REPO_TOOLS = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-tools"
_REPO_CONFIGS = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-configs"
_PREBUILT_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-preboot"

# pass all this to the environment
os.environ['_DEPLOY_DIR'] = _DEPLOY_DIR
os.environ['_REPO_PATH'] = _REPO_PATH
os.environ['_REPO_TOOLS'] = _REPO_TOOLS
os.environ['_REPO_CONFIGS'] = _REPO_CONFIGS
os.environ['_PREBUILT_PATH'] = _PREBUILT_PATH
$_DEPLOY_DIR = _DEPLOY_DIR
$_REPO_PATH = _REPO_PATH
$_REPO_TOOLS = _REPO_TOOLS
$_REPO_CONFIGS = _REPO_CONFIGS
$_PREBUILT_PATH = _PREBUILT_PATH


# sign the u-boot
_u_boot = f"{_REPO_PATH}/u-boot.bin"
cp -ad @(_u_boot) @(f"{_REPO_PATH}/uboot_raw.bin")

os.chdir(f"{_REPO_TOOLS}/tools/bin")

# header aligns to 64 byte
dd if=/dev/zero of=@(f"{_REPO_PATH}")/uboot_prepending.bin bs=1 count=48
cat @(f"{_REPO_PATH}")/uboot_prepending.bin @(f"{_REPO_PATH}")/uboot_raw.bin > @(f"{_REPO_PATH}")/uboot_raw_prepending.bin
# mv @(f"{_REPO_PATH}")/uboot_raw_prepending.bin @(f"{_REPO_PATH}")/uboot_raw.bin

# create in_extras
./in_extras.py \
    "BOOT_LOADER" \
    @(f"{_REPO_PATH}")/in_uboot_extras.bin 0x00000001

# sign
sudo \
    -E \
    ./gen_x_secure_image \
        --chip-name=dolphin \
        --chip-rev=A0 \
        --img_type=BOOT_LOADER \
        --key_type=ree \
        --length=0x0 \
        --extras=@(f"{_REPO_PATH}")/in_uboot_extras.bin \
        --workdir-security-tools=@(f"{_REPO_TOOLS}/tools/bin") \
        --workdir-security-keys=@(f"{_path}/{_MACHINE}") \
        --in_payload=@(f"{_REPO_PATH}")/uboot_raw_prepending.bin \
        --out_store=@(f"{_DEPLOY_DIR}/uboot_en.bin")

# bootloader.subimg
sudo -E ./prepend_image_info.sh \
        @(f"{_DEPLOY_DIR}/uboot_en.bin") \
        @(f"{_DEPLOY_DIR}/bootloader_nopreload.subimg")

# call the gen-container.sh
sudo \
    -E \
    bash \
        @(f"{_path}/gen-container.sh")


print("Deploying astra u-boot artifacts, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
