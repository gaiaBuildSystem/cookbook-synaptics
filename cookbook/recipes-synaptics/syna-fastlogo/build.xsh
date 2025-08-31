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


print("building syna-fastlogo ...", color=Color.WHITE, bg_color=BgColor.GREEN)

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
_DEPLOY_DIR = f"{_BUILD_PATH}/tmp/{_MACHINE}/deploy"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT
_REPO_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-fastlogo"
_REPO_TOOLS = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-tools"

# make sure the repo path exists
mkdir -p @(_REPO_PATH)

# copy the create_fastlogo script from tools
cp @(_REPO_TOOLS)/tools/bin/create_fastlogo.sh @(_REPO_PATH)/

# cleanup if already exists
if os.path.exists(f"{_REPO_PATH}/fastlogo.subimg.gz"):
    rm @(_REPO_PATH)/fastlogo.subimg.gz

# now create the fastlogo
os.chdir(_REPO_PATH)
./create_fastlogo.sh \
    -i @(_path)/splash.bmp \
    -o fastlogo.subimg

# copy it to the deploy path
sudo mkdir -p @(_DEPLOY_DIR)
sudo cp fastlogo.subimg.gz @(_DEPLOY_DIR)/


print("Building syna-fastlogo, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
