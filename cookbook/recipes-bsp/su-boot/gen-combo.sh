#!/bin/bash

set -e

# TODO: these make sense for dolphin only
spi_vt_size=2048
spi_header_size=1024

spi_page_size=256
spi_block_size=65536
spi_total_size=33554432
spi_boot_part_size=524288


f_preboot=$1; shift
f_tee=$1; shift
f_bl=$1; shift
f_spi_combo=$1; shift

#Dynamic partition size calculation
f_spi_pt="${_REPO_CONFIGS}/product/sl1680_spi_poky_aarch64_rdk/spi.pt"
spi_preboot_end=$(awk '$2 == "preboot_a" { sub(/K$/, "", $1); print $1 * 1024 }' "$f_spi_pt")
spi_tzk_end=$[$spi_preboot_end + $(awk '$2 == "tzk_a" { sub(/K$/, "", $1); print $1 * 1024 }' "$f_spi_pt")]
spi_bl_end=$[$spi_tzk_end + $(awk '$2 == "bl_a" { sub(/K$/, "", $1); print $1 * 1024 }' "$f_spi_pt")]

# Pack preboot
dd if=/dev/zero bs=1024 count=1 > $f_spi_combo
cat $f_preboot >> $f_spi_combo

preboot_size=`stat -c %s ${f_spi_combo}`
padding_size=$[$spi_preboot_end - $preboot_size]

f_PADDING=${_DEPLOY_DIR}/dummy.bin
dd if=/dev/zero of=$f_PADDING bs=1 count=$padding_size
cat $f_PADDING >> $f_spi_combo

echo "f_tee: $f_tee"
echo "f_spi_combo: $f_spi_combo"

# Pack TEE
cat $f_tee >> $f_spi_combo

tee_size=`stat -c %s ${f_spi_combo}`
padding_size=$[$spi_tzk_end - $tee_size]

f_PADDING=${_DEPLOY_DIR}/dummy.bin
dd if=/dev/zero of=$f_PADDING bs=1 count=$padding_size
cat $f_PADDING >> $f_spi_combo

# Pack BL
cat $f_bl >> $f_spi_combo

bl_size=`stat -c %s ${f_spi_combo}`
padding_size=$[$spi_bl_end - $bl_size]

f_PADDING=${_DEPLOY_DIR}/dummy.bin
dd if=/dev/zero of=$f_PADDING bs=1 count=$padding_size
cat $f_PADDING >> $f_spi_combo
rm $f_PADDING
