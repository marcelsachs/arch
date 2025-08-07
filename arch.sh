#!/bin/bash
set -euo pipefail
source config.txt

echo "This will wipe your entire $DISK, you sure? (y/n)"
read -r confirm
[[ "$confirm" == "y" ]] || exit 1

sgdisk -Z "$DISK"
sgdisk -n 1:0:+"$EFI_SIZE" -t 1:ef00 "$DISK"
sgdisk -n 2:0:+"$ROOT_SIZE" -t 2:8300 "$DISK"
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 "${DISK}p2"
mount "${DISK}p2" /mnt
mount --mkdir "${DISK}p1" /mnt/boot
reflector --country "$COUNTRY" --age 12 --latest 10 --fastest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K /mnt "${START_PACKAGES[@]}"
genfstab -U /mnt >> /mnt/etc/fstab
cp config.txt /mnt
cp chroot.sh /mnt
chmod +x chroot.sh
arch-chroot /mnt ./chroot.sh
rm -rf /mnt/chroot.sh /mnt/config.txt
echo "Finished. You can now 'umount -R /mnt' and then reboot."
