#!/bin/bash
# disk.sh - Disk partitioning, formatting, and mounting

set -euo pipefail

source config.sh  # In case run standalone, but main sources it

get_partition_name() {
    echo "${DISK}p${1}"
}

echo "-> Partitioning disk..."
sgdisk -Z "$DISK"
sgdisk -n 1:0:+"$EFI_SIZE" -t 1:ef00 "$DISK"
sgdisk -n 2:0:+"$ROOT_SIZE" -t 2:8300 "$DISK"

echo "-> Formatting partitions..."
EFI_PARTITION=$(get_partition_name 1)
ROOT_PARTITION=$(get_partition_name 2)
mkfs.fat -F32 "$EFI_PARTITION"
mkfs.ext4 "$ROOT_PARTITION"

echo "-> Mounting partitions..."
mount "$ROOT_PARTITION" /mnt
mount --mkdir "$EFI_PARTITION" /mnt/boot
