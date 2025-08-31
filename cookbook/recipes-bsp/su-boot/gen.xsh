#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$RAISE_SUBPROC_ERROR = True
$XONSH_SHOW_TRACEBACK = True


import os
import sys
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error

print("deploying su-boot ...", color=Color.WHITE, bg_color=BgColor.GREEN)

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
_REPO_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/su-boot"
_REPO_TOOLS = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-tools"
_REPO_CONFIGS = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-configs"
_PREBUILT_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-preboot"

spi_vt_size = 2048
spi_header_size = 1024

# TODO: these make sense for dolphin only
spi_page_size=256
spi_block_size=65536
spi_total_size=33554432
spi_boot_part_size=524288


# def gen_preboot_subimg(f_input):
#     # Fill the gap
#     f_len = $(stat -c %s @{f_input})
#     assert not (f_len + 2048) > spi_boot_part_size

#     fill_length = spi_boot_part_size - spi_vt_size - spi_header_size - f_len
#     dd if=/dev/zero bs=@(f"{fill_length}") count=1 >> @(f"{f_input}")

#     # Append version table
#     cat @(f"{_DEPLOY_DIR}/version_table") >> @(f"{f_input}")

#     # Append to block size
#     f_len = $(stat -c %s @(f"{f_input}"))
#     assert not f_len > spi_boot_part_size

#     fill_length = spi_boot_part_size - spi_header_size - f_len
#     dd if=/dev/zero bs=@(f"{fill_length}") count=1 >> @(f"{f_input}")


def genx_spi_suboot_combo(f_preboot, f_tee, f_bl, f_spi_combo):
    preboot_size = 0
    tee_size = 0
    bl_size = 0
    spi_tzk_end = 0
    spi_bl_end = 0
    spi_preboot_end = 0
    padding_size = 0

    # Dynamic partition size calculation
    f_spi_pt = f"{_REPO_CONFIGS}/product/sl1680_spi_poky_aarch64_rdk/spi.pt"
    spi_preboot_end = $(awk '$2 == "preboot_a" { sub(/K$/, "", $1); print $1 * 1024 }' @(f"{f_spi_pt}"))
    spi_tzk_end = spi_preboot_end + $(awk '$2 == "tzk_a" { sub(/K$/, "", $1); print $1 * 1024 }' @(f"{f_spi_pt}"))
    spi_bl_end = spi_tzk_end + $(awk '$2 == "bl_a" { sub(/K$/, "", $1); print $1 * 1024 }' @(f"{f_spi_pt}"))


    # Pack preboot
    print("pack preboot ...")
    dd if=/dev/zero bs=1024 count=1 > @(f"{f_spi_combo}")
    cat @(f"{f_preboot}") >> @(f"{f_spi_combo}")

    preboot_size = $(stat -c %s @(f"{f_spi_combo}"))
    padding_size = int(spi_preboot_end) - int(preboot_size)

    # debug the values
    print(f"preboot_size: {preboot_size}")
    print(f"tee_size: {tee_size}")
    print(f"bl_size: {bl_size}")
    print(f"spi_tzk_end: {spi_tzk_end}")
    print(f"spi_bl_end: {spi_bl_end}")
    print(f"spi_preboot_end: {spi_preboot_end}")
    print(f"padding_size: {padding_size}")

    print("dummy to padding_size ...")
    f_PADDING = f"{_DEPLOY_DIR}/dummy.bin"
    dd if=/dev/zero of=@(f"{f_PADDING}") bs=1 count=@(f"{padding_size}")
    print("dummy to padding_size cat ...")
    cat @(f"{f_PADDING}") >> @(f"{f_spi_combo}")

    # Pack TEE
    print("tee cat ...")
    cat @(f"{f_tee}") >> @(f"{f_spi_combo}")

    tee_size = $(stat -c %s @(f"{f_spi_combo}"))
    padding_size = int(spi_tzk_end) - int(tee_size)

    # debug the values
    print(f"preboot_size: {preboot_size}")
    print(f"tee_size: {tee_size}")
    print(f"bl_size: {bl_size}")
    print(f"spi_tzk_end: {spi_tzk_end}")
    print(f"spi_bl_end: {spi_bl_end}")
    print(f"spi_preboot_end: {spi_preboot_end}")
    print(f"padding_size: {padding_size}")

    print("pack tee ...")
    dd if=/dev/zero of=@(f"{f_PADDING}") bs=1 count=@(f"{padding_size}")
    cat @(f"{f_PADDING}") >> @(f"{f_spi_combo}")

    # Pack BL
    cat @(f"{f_bl}") >> @(f"{f_spi_combo}")

    bl_size = $(stat -c %s @(f"{f_spi_combo}"))
    padding_size = int(spi_bl_end) - int(bl_size)

    # debug the values
    print(f"preboot_size: {preboot_size}")
    print(f"tee_size: {tee_size}")
    print(f"bl_size: {bl_size}")
    print(f"spi_tzk_end: {spi_tzk_end}")
    print(f"spi_bl_end: {spi_bl_end}")
    print(f"spi_preboot_end: {spi_preboot_end}")
    print(f"padding_size: {padding_size}")

    print("pack uboot ...")
    dd if=/dev/zero of=@(f"{f_PADDING}") bs=1 count=@(f"{padding_size}")
    cat @(f"{f_PADDING}") >> @(f"{f_spi_combo}")
    rm @(f"{f_PADDING}")


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
./prepend_image_info.sh \
    @(f"{_DEPLOY_DIR}/uboot_en.bin") \
    @(f"{_DEPLOY_DIR}/bootloader_nopreload.subimg")

# parsing the spi.pt
os.chdir(f"{_REPO_TOOLS}/tools/src/executables/parse_pt")
./parse_pt \
    0 0 \
    @(f"{spi_block_size}") @(f"{spi_total_size}") \
    @(f"{_REPO_CONFIGS}/product/sl1680_spi_poky_aarch64_rdk/spi.pt") \
    @(f"{_DEPLOY_DIR}/linux_params_mtdparts") \
    @(f"{_DEPLOY_DIR}/version_table") \
    @(f"{_DEPLOY_DIR}/subimglayout")

# gen preboot.subimg
# gen_preboot_subimg(f"{_DEPLOY_DIR}/preboot.subimg")

# Make spi_suboot.bin which including preboot, tee and bootloader subimg
genx_spi_suboot_combo(
    f_preboot=f"{_PREBUILT_PATH}/preboot.subimg",
    f_tee=f"{_PREBUILT_PATH}/tee.subimg",
    f_bl=f"{_DEPLOY_DIR}/bootloader_nopreload.subimg",
    f_spi_combo=f"{_DEPLOY_DIR}/spi_suboot.bin"
)

# generate the spi combo
# _uboot_img = f"{_DEPLOY_DIR}/u-boot-spi.img"
# _uboot_en = f"{_DEPLOY_DIR}/uboot_en.bin"
# _dolphin_prebuilts = f"{_PREBUILT_PATH}/bcm_ree/dolphin/A0/1/bootflow/NR/EMMC/fastboot_n"
# _dolphin_prebuilts_hwinit = f"{_PREBUILT_PATH}/bcm_ree/dolphin/A0/1/hwinit/lpddr4/2GB/3733/default/default/EMMC"
# _erom = f"{_dolphin_prebuilts}/erom.bin"
# _tsm = f"{_dolphin_prebuilts}/tsm.bin"
# _ddrphyfw = f"{_dolphin_prebuilts_hwinit}/ddrphy.bin"
# _sysinit = f"{_dolphin_prebuilts_hwinit}/sysinit_en.bin"

# dd if=/dev/zero bs=1024 count=1 > @(f"{_uboot_img}")
# cat @(f"{_erom}") @(f"{_sysinit}") @(f"{_ddrphyfw}") @(f"{_uboot_en}") @(f"{_tsm}") >> @(f"{_uboot_img}")

print("deploying su-boot, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
