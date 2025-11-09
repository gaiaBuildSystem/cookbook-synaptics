#!/bin/bash

set -e

_path=$(dirname "$0")

# deploy the mount root script
cp $_path/busybox/00-modeset.sh $INITRAMFS_PATH/scripts/00-modeset.sh
