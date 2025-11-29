#!/bin/bash

set -e

BASE="/home/ubuntu-armhf"
ROOTFS="$BASE/rootfs"
IMG="$BASE/ubuntu-armhf.ext4"
IMG_MOUNT="$BASE/img"

echo "== PREPARING ENVIRONMENT =="

# Install required tools
sudo apt update
sudo apt install -y debootstrap qemu-user-static binfmt-support rsync

# Create base directory
sudo mkdir "$BASE"
sudo mkdir -p "$ROOTFS"
sudo chown -R $USER:$USER "$BASE"

# Clean any old rootfs
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"

# Ensure qemu-user-static is present
if [ ! -f /usr/bin/qemu-arm-static ]; then
    echo "Installing qemu-arm-static"
    sudo apt install -y qemu-user-static
fi

echo "== STAGE 1: DEBOOTSTRAP =="
sudo debootstrap --arch=armhf --foreign focal "$ROOTFS" http://ports.ubuntu.com/

echo "== STAGE 2: ARM EMULATION SETUP =="
sudo cp /usr/bin/qemu-arm-static "$ROOTFS/usr/bin/"

echo "== STAGE 2: COMPLETING DEBOOTSTRAP =="
sudo chroot "$ROOTFS" /debootstrap/debootstrap --second-stage

echo "== CREATING EXT4 IMAGE =="
sudo rm -f "$IMG"
sudo dd if=/dev/zero of="$IMG" bs=1M count=4096
sudo mkfs.ext4 -F "$IMG"

echo "== MOUNTING EXT4 IMAGE =="
sudo mkdir -p "$IMG_MOUNT"
sudo mount -o loop "$IMG" "$IMG_MOUNT"

echo "== COPYING ROOTFS INTO IMAGE =="
sudo rsync -a "$ROOTFS"/ "$IMG_MOUNT"/

echo "== SYNCING & UNMOUNTING =="
sync
sudo umount "$IMG_MOUNT"

echo "🎉 DONE!"
echo "Your file is ready at:"
echo "➡ $IMG"

