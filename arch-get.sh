#!/bin/bash

set -e

USB_DEVICE="${1:-sda}"

if [ ! -b "/dev/$USB_DEVICE" ]; then
    echo "Device /dev/$USB_DEVICE not found"
    exit 1
fi

echo "⚠️  WARNING: Will wipe /dev/$USB_DEVICE"
read -p "Type YES to continue: " confirm
[ "$confirm" = "YES" ] || exit 1

sudo umount "/dev/$USB_DEVICE"* 2>/dev/null || true

echo "Streaming ISO directly to USB..."
curl -L "https://ftp.fau.de/archlinux/iso/latest/archlinux-x86_64.iso" | \
    sudo dd of="/dev/$USB_DEVICE" bs=4M status=progress oflag=sync

sudo sync
echo "Done!"
