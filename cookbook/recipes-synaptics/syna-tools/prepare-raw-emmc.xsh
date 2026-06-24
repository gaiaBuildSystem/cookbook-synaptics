#!/usr/bin/env xonsh

# Copyright (c) 2025 MicroHobby
# SPDX-License-Identifier: MIT

# use the xonsh environment to update the OS environment
$UPDATE_OS_ENVIRON = True
# always return if a cmd fails
$XONSH_SUBPROC_CMD_RAISE_ERROR = True


import os
import json
import os.path
from torizon_templates_utils.colors import print,BgColor,Color
from torizon_templates_utils.errors import Error_Out,Error


print("syna-tools preparing raw emmc image ...", color=Color.WHITE, bg_color=BgColor.GREEN)

# get the common variables
_ARCH = os.environ.get('ARCH')
_MACHINE = os.environ.get('MACHINE')
_MAX_IMG_SIZE = os.environ.get('MAX_IMG_SIZE')
_BUILD_PATH = os.environ.get('BUILD_PATH')
_DISTRO_MAJOR = os.environ.get('DISTRO_MAJOR')
_DISTRO_MINOR = os.environ.get('DISTRO_MINOR')
_DISTRO_PATCH = os.environ.get('DISTRO_PATCH')
_USER_PASSWD = os.environ.get('USER_PASSWD')
_DISTRO_VARIANT = os.environ.get('DISTRO_VARIANT')

# read the meta data
meta = json.loads(os.environ.get('META', '{}'))

# get the actual script path, not the process.cwd
_path = os.path.dirname(os.path.abspath(__file__))

_IMAGE_MNT_BOOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/boot"
_IMAGE_MNT_ROOT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/root"
_DEPLOY_DIR = f"{_BUILD_PATH}/tmp/{_MACHINE}/deploy"
os.environ['IMAGE_MNT_BOOT'] = _IMAGE_MNT_BOOT
os.environ['IMAGE_MNT_ROOT'] = _IMAGE_MNT_ROOT
_REPO_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-tools"
_EXECUTABLES_PATH = f"{_REPO_PATH}/tools/src/executables"
_EMMC_PT_PATH = f"{_BUILD_PATH}/tmp/{_MACHINE}/syna-configs/product/sl1680_poky_aarch64_rdk/emmc.pt"

# make sure that the deploy dir is created
sudo mkdir -p @(_DEPLOY_DIR)

# first we need to create the rootfs.subimg.gz
# calculate the size of the rootfs directory (in KB), excluding virtual filesystems
print("Calculating rootfs size (excluding virtual filesystems)...", color=Color.WHITE, bg_color=BgColor.BLUE)
_ROOTFS_SIZE_KB = $(sudo du -sk --exclude=proc --exclude=sys --exclude=dev --exclude=run --exclude=tmp @(_IMAGE_MNT_ROOT) | cut -f1)
_ROOTFS_SIZE_MB = int(int(_ROOTFS_SIZE_KB) / 1024)
# Add significant padding: 50% extra space + minimum 500MB for filesystem overhead
_PADDING_MB = max(int(_ROOTFS_SIZE_MB * 0.5), 500)
_TOTAL_SIZE_MB = _ROOTFS_SIZE_MB + _PADDING_MB

print(f"Rootfs content size: {_ROOTFS_SIZE_MB}MB, padding: {_PADDING_MB}MB, total: {_TOTAL_SIZE_MB}MB", color=Color.WHITE, bg_color=BgColor.BLUE)

# create the rootfs image file
_ROOTFS_IMG = f"{_DEPLOY_DIR}/rootfs.img"
sudo dd if=/dev/zero of=@(_ROOTFS_IMG) bs=1M count=@(_TOTAL_SIZE_MB) status=progress

# format as ext4 with more inodes and reserved space
sudo mkfs.ext4 -F -m 1 -N 500000 @(_ROOTFS_IMG)
sudo e2label @(_ROOTFS_IMG) "rootfs"

# mount the image to copy rootfs content
_TEMP_MNT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/temp_rootfs"
sudo mkdir -p @(_TEMP_MNT)
sudo mount -o loop @(_ROOTFS_IMG) @(_TEMP_MNT)

try:
    # copy rootfs content excluding virtual filesystems
    print("Copying rootfs content to image (excluding virtual filesystems)...", color=Color.WHITE, bg_color=BgColor.BLUE)
    sudo rsync -aHS \
        --exclude=/proc \
        --exclude=/sys \
        --exclude=/dev \
        --exclude=/run \
        --exclude=/tmp \
        --exclude=/lost+found \
        @(f"{_IMAGE_MNT_ROOT}/") @(f"{_TEMP_MNT}/")

    if _DISTRO_VARIANT != "bootc":
        # create essential empty directories in the new rootfs
        sudo mkdir -p @(f"{_TEMP_MNT}/proc")
        sudo mkdir -p @(f"{_TEMP_MNT}/sys")
        sudo mkdir -p @(f"{_TEMP_MNT}/dev")
        sudo mkdir -p @(f"{_TEMP_MNT}/run")
        sudo mkdir -p @(f"{_TEMP_MNT}/tmp")

        # set proper permissions
        sudo chmod 1777 @(f"{_TEMP_MNT}/tmp")
        sudo chmod 755 @(f"{_TEMP_MNT}/proc") @(f"{_TEMP_MNT}/sys") @(f"{_TEMP_MNT}/dev") @(f"{_TEMP_MNT}/run")

    sync  # ensure all data is written
    print("Rootfs image created successfully", color=Color.WHITE, bg_color=BgColor.BLUE)

except Exception as e:
    print("syna-tools preparing raw emmc, OOPS at rootfs...", color=Color.WHITE, bg_color=BgColor.RED)
    print(e)
finally:
    # always unmount
    sudo umount @(_TEMP_MNT) || true
    sudo rmdir @(_TEMP_MNT) || true


# to the same for boot partition
print("Calculating boot partition size...", color=Color.WHITE, bg_color=BgColor.BLUE)
_BOOT_SIZE_KB = $(sudo du -sk @(_IMAGE_MNT_BOOT) | cut -f1)
_BOOT_SIZE_MB = int(int(_BOOT_SIZE_KB) / 1024)
_PADDING_BOOT_MB = max(int(_BOOT_SIZE_MB * 0.5), 100)
_TOTAL_BOOT_SIZE_MB = _BOOT_SIZE_MB + _PADDING_BOOT_MB
print(f"Boot content size: {_BOOT_SIZE_MB}MB, padding: {_PADDING_BOOT_MB}MB, total: {_TOTAL_BOOT_SIZE_MB}MB", color=Color.WHITE, bg_color=BgColor.BLUE)

_BOOT_IMG = f"{_DEPLOY_DIR}/boot.img"
sudo dd if=/dev/zero of=@(_BOOT_IMG) bs=1M count=@(_TOTAL_BOOT_SIZE_MB) status=progress

# format as FAT32 for bootloader
sudo mkfs.vfat -F 32 @(_BOOT_IMG)
sudo fatlabel @(_BOOT_IMG) BOOT

_TEMP_BOOT_MNT = f"{_BUILD_PATH}/tmp/{_MACHINE}/mnt/temp_boot"
sudo mkdir -p @(_TEMP_BOOT_MNT)
sudo mount -o loop @(_BOOT_IMG) @(_TEMP_BOOT_MNT)

try:
    print("Copying boot partition content...", color=Color.WHITE, bg_color=BgColor.BLUE)
    sudo rsync -av @(f"{_IMAGE_MNT_BOOT}/") @(f"{_TEMP_BOOT_MNT}/")
    sync
    print("Boot image created successfully", color=Color.WHITE, bg_color=BgColor.BLUE)
except Exception as e:
    print("syna-tools preparing raw emmc, OOPS at boot...", color=Color.WHITE, bg_color=BgColor.RED)
    print(e)
finally:
    sudo umount @(_TEMP_BOOT_MNT) || true
    sudo rmdir @(_TEMP_BOOT_MNT) || true


# --- RAW eMMC IMAGE ASSEMBLY ---
# Build a single raw image containing all GPT partitions populated with
# the pre-built sub-images and the rootfs/boot we just created above.

print("Assembling raw eMMC image...", color=Color.WHITE, bg_color=BgColor.BLUE)

# Gather pre-built sub-images into a working directory
_EMMC_WORK_DIR = f"{_DEPLOY_DIR}/emmc_work"
sudo mkdir -p @(_EMMC_WORK_DIR)

sudo cp @(_path)/@(f"eMMCimg_{_MACHINE}")/*.subimg.gz @(_EMMC_WORK_DIR)/

# bl.subimg.gz (and fastlogo.subimg.gz) are produced by the build and land in DEPLOY_DIR
sudo mv @(_DEPLOY_DIR)/bl.subimg.gz @(_EMMC_WORK_DIR)/

if _MACHINE == "luna" or _MACHINE == "astra-sl1680":
    sudo mv @(_DEPLOY_DIR)/fastlogo.subimg.gz @(_EMMC_WORK_DIR)/

# Parse emmc_part_list.template substituting the actual rootfs size
_emmc_part_list_template = f"{_path}/eMMCimg_{_MACHINE}/emmc_part_list.template"
with open(_emmc_part_list_template, 'r') as _f:
    _part_list_content = _f.read()
_part_list_content = _part_list_content.replace('{{ROOTFS_SIZE}}', str(_TOTAL_SIZE_MB))

# Build ordered list of (partition_name, size_mb)
_partitions = []
for _line in _part_list_content.splitlines():
    _line = _line.strip()
    if _line.startswith('#') or not _line:
        continue
    _cols = [_c.strip() for _c in _line.split(',')]
    if len(_cols) < 3 or not _cols[2]:
        continue
    _partitions.append((_cols[0], int(_cols[2])))

# Total image size: 1MB alignment gap + all partition sizes + 1MB GPT backup
_TOTAL_EMMC_MB = 1 + sum(_sz for _, _sz in _partitions) + 1
print(f"Raw eMMC image size: {_TOTAL_EMMC_MB}MB ({len(_partitions)} GPT partitions)", color=Color.WHITE, bg_color=BgColor.BLUE)

# Create the zeroed raw image file
_RAW_EMMC_IMG = f"{_DEPLOY_DIR}/emmc.img"
sudo dd if=/dev/zero of=@(_RAW_EMMC_IMG) bs=1M count=@(_TOTAL_EMMC_MB) status=progress

# Build GPT partition table with sgdisk
# Sector size is 512 bytes; start at sector 2048 (1MiB alignment)
_SECTOR_SIZE = 512
_SECTORS_PER_MB = (1024 * 1024) // _SECTOR_SIZE  # 2048
_current_sector = 2048

_sgdisk_args = ['--clear']
for _i, (_pname, _psize_mb) in enumerate(_partitions):
    _size_sectors = _psize_mb * _SECTORS_PER_MB
    _end_sector = _current_sector + _size_sectors - 1
    _sgdisk_args += [
        f'-n {_i+1}:{_current_sector}:{_end_sector}',
        f'-c {_i+1}:{_pname}',
    ]
    _current_sector = _end_sector + 1

print("Creating GPT partition table...", color=Color.WHITE, bg_color=BgColor.BLUE)
sudo sgdisk @(_sgdisk_args) @(_RAW_EMMC_IMG)

# Build a map of partition number -> byte offset in the image file.
# We track start offsets using the same sector layout computed for sgdisk,
# so writes land precisely where the GPT table says each partition begins.
_part_byte_offsets = {}  # partition_number (1-based) -> start byte offset
_offset_sector = 2048
for _i, (_pname, _psize_mb) in enumerate(_partitions):
    _part_byte_offsets[_i + 1] = _offset_sector * _SECTOR_SIZE
    _offset_sector += _psize_mb * _SECTORS_PER_MB

# Parse emmc_image_list to know which sub-image goes to which sdN partition
_image_list = []
_emmc_image_list_file = f"{_path}/eMMCimg_{_MACHINE}/emmc_image_list"
with open(_emmc_image_list_file, 'r') as _f:
    for _line in _f:
        _line = _line.strip()
        if not _line:
            continue
        _cols = _line.split(',')
        if len(_cols) == 2:
            _image_list.append((_cols[0].strip(), _cols[1].strip()))

# rootfs goes to the last GPT partition (sd<N>)
_rootfs_part = f"sd{len(_partitions)}"
_image_list.append(('rootfs', _rootfs_part))

# Write each sub-image directly into the raw image file at the correct byte
# offset using dd seek.  No loop device or kernel partition driver involved,
# so there is no risk of the kernel mis-reporting partition sizes.
print("Writing sub-images to raw eMMC image...", color=Color.WHITE, bg_color=BgColor.BLUE)

for _img_file, _part in _image_list:
    if _part.startswith('b'):
        # eMMC hardware boot partition (b1/b2): cannot live inside the GPT
        # image, so save it as a standalone file to be flashed separately.
        _boot_num = _part[1]
        _boot_out = f"{_DEPLOY_DIR}/preboot_boot{_boot_num}.img"
        print(f"Saving eMMC boot partition {_part} -> preboot_boot{_boot_num}.img", color=Color.WHITE, bg_color=BgColor.BLUE)
        sudo bash -c @(f"gunzip -c {_EMMC_WORK_DIR}/{_img_file} > {_boot_out}")
        continue

    if _img_file == 'format':
        # Partition is already zero-filled; nothing to write
        continue

    # sdN -> partition number N -> byte offset in the image file
    _part_num = int(_part[2:])
    _seek_sectors = _part_byte_offsets[_part_num] // _SECTOR_SIZE

    print(f"Writing {_img_file} -> {_part} (sector {_seek_sectors}, offset {_part_byte_offsets[_part_num] // (1024*1024)}MB)", color=Color.WHITE, bg_color=BgColor.BLUE)

    if _img_file == 'boot.subimg.gz':
        # Use the boot.img built above (dd with seek, conv=notrunc to keep the rest of the file)
        sudo bash -c @(f"dd if={_BOOT_IMG} of={_RAW_EMMC_IMG} bs=512 seek={_seek_sectors} conv=notrunc status=progress")

    elif _img_file == 'rootfs':
        # Use the rootfs.img built above
        sudo bash -c @(f"dd if={_ROOTFS_IMG} of={_RAW_EMMC_IMG} bs=512 seek={_seek_sectors} conv=notrunc status=progress")

    else:
        # Decompress and write the pre-built sub-image
        _subimg = f"{_EMMC_WORK_DIR}/{_img_file}"
        sudo bash -c @(f"gunzip -c {_subimg} | dd of={_RAW_EMMC_IMG} bs=512 seek={_seek_sectors} conv=notrunc status=progress")

sync
print("All partitions written successfully", color=Color.WHITE, bg_color=BgColor.BLUE)


# Compress the final raw eMMC image
_RAW_EMMC_IMG_GZ = f"{_RAW_EMMC_IMG}.gz"
print("Compressing raw eMMC image...", color=Color.WHITE, bg_color=BgColor.BLUE)
sudo bash -c @(f"gzip -fc {_RAW_EMMC_IMG} > {_RAW_EMMC_IMG_GZ}")

print(f"Raw eMMC image: {_RAW_EMMC_IMG}", color=Color.WHITE, bg_color=BgColor.BLUE)
print(f"Compressed eMMC image: {_RAW_EMMC_IMG_GZ}", color=Color.WHITE, bg_color=BgColor.BLUE)
print(f"eMMC boot0 partition: {_DEPLOY_DIR}/preboot_boot0.img (flash to /dev/mmcblkXboot0)", color=Color.WHITE, bg_color=BgColor.BLUE)
print(f"eMMC boot1 partition: {_DEPLOY_DIR}/preboot_boot1.img (flash to /dev/mmcblkXboot1)", color=Color.WHITE, bg_color=BgColor.BLUE)

# Remove intermediate files
sudo rm -f @(_ROOTFS_IMG)
sudo rm -f @(_BOOT_IMG)
sudo rm -rf @(_EMMC_WORK_DIR)


print("syna-tools preparing raw emmc image, OK", color=Color.WHITE, bg_color=BgColor.GREEN)
