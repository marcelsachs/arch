#!/bin/bash
set -euo pipefail
source config.txt

# Function to get partition name based on disk type
get_partition_name() {
    local disk="$1"
    local partition_num="$2"
    
    if [[ "$disk" == *"nvme"* ]] || [[ "$disk" == *"mmcblk"* ]]; then
        echo "${disk}p${partition_num}"
    else
        echo "${disk}${partition_num}"
    fi
}

run_in_chroot() {
    arch-chroot /mnt /bin/bash -c "$1"
}

echo "==============================================="
echo "Quick Arch Linux Installation"
echo "==============================================="
echo "Disk: $DISK"
echo "Hostname: $HOSTNAME"
echo "User: $USER_NAME"
echo "Timezone: $TIMEZONE"
echo "==============================================="
echo "WARNING: COMPLETELY WIPE $DISK"
echo "Type 'yes' to continue:"
read -r confirm
[[ "$confirm" == "yes" ]] || { echo "Installation cancelled."; exit 1; }

echo "-> Detecting boot mode..."
if [[ -d /sys/firmware/efi/efivars ]]; then
    BOOT_MODE="uefi"
    echo "UEFI boot mode detected"
else
    BOOT_MODE="bios"
    echo "Legacy BIOS boot mode detected"
fi

echo "-> Partitioning disk..."
sgdisk -Z "$DISK"

if [[ "$BOOT_MODE" == "uefi" ]]; then
    # UEFI partitioning
    sgdisk -n 1:0:+"$EFI_SIZE" -t 1:ef00 "$DISK"
    sgdisk -n 2:0:+"$ROOT_SIZE" -t 2:8300 "$DISK"
else
    # BIOS partitioning with BIOS boot partition
    sgdisk -n 1:0:+1M -t 1:ef02 "$DISK"           # BIOS boot partition (1MB)
    sgdisk -n 2:0:+"$ROOT_SIZE" -t 2:8300 "$DISK"  # Root partition
fi

echo "-> Formatting partitions..."
if [[ "$BOOT_MODE" == "uefi" ]]; then
    EFI_PARTITION=$(get_partition_name "$DISK" "1")
    ROOT_PARTITION=$(get_partition_name "$DISK" "2")
    
    mkfs.fat -F32 "$EFI_PARTITION"
    mkfs.ext4 "$ROOT_PARTITION"
    
    echo "-> Mounting partitions..."
    mount "$ROOT_PARTITION" /mnt
    mount --mkdir "$EFI_PARTITION" /mnt/boot
else
    # BIOS mode - partition 1 is BIOS boot (no filesystem), partition 2 is root
    ROOT_PARTITION=$(get_partition_name "$DISK" "2")
    
    mkfs.ext4 "$ROOT_PARTITION"
    
    echo "-> Mounting partitions..."
    mount "$ROOT_PARTITION" /mnt
fi

echo "-> Updating mirrorlist..."
reflector --country "$COUNTRY" --latest 10 --fastest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

echo "-> Installing base system..."
pacstrap -K /mnt "${PACKAGES[@]}"

echo "-> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

cp config.txt /mnt/root/

echo "-> Configuring system..."

run_in_chroot "echo 'root:$ROOT_PASSWORD' | chpasswd"

run_in_chroot "ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime"
run_in_chroot "hwclock --systohc"

for loc in "${LOCALES[@]}"; do
    run_in_chroot "sed -i 's/^# *$loc/$loc/' /etc/locale.gen"
done
run_in_chroot "locale-gen"
run_in_chroot "echo 'LANG=$LANG' > /etc/locale.conf"

run_in_chroot "echo 'KEYMAP=$KEYMAP' > /etc/vconsole.conf"

run_in_chroot "echo '$HOSTNAME' > /etc/hostname"

echo "-> Configuring network..."
{
    run_in_chroot 'ETHERNET_INTERFACE=$(ip -o link show | awk -F": " "/: en|: eth/ {print \$2}" | head -n 1 || true)
    if [[ -n "$ETHERNET_INTERFACE" ]]; then
        printf "[Match]\nName=%s\n\n[Network]\nDHCP=yes\n" "$ETHERNET_INTERFACE" > /etc/systemd/network/10-wired.network
    fi'
    run_in_chroot 'WLAN_INTERFACE=$(ip -o link show | awk -F": " "/: wl/ {print \$2}" | head -n 1 || true)
    if [[ -n "$WLAN_INTERFACE" ]]; then
        printf "[Match]\nName=%s\n\n[Network]\nDHCP=yes\n" "$WLAN_INTERFACE" > /etc/systemd/network/20-wireless.network
    fi'
} || echo "Warning: Network configuration failed, but continuing installation..."

echo "-> Installing bootloader..."
if [[ "$BOOT_MODE" == "uefi" ]]; then
    run_in_chroot "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB"
else
    run_in_chroot "grub-install --target=i386-pc $DISK"
fi

run_in_chroot "sed -i 's/^#\(GRUB_DISABLE_OS_PROBER=.*\)/\1/' /etc/default/grub"
run_in_chroot "grub-mkconfig -o /boot/grub/grub.cfg"

echo "-> Creating user $USER_NAME..."
run_in_chroot "useradd -m -d '$HOME_DIR' -s /bin/bash '$USER_NAME'"
run_in_chroot "echo '$USER_NAME:$USER_PASSWORD' | chpasswd"
run_in_chroot "echo '$USER_NAME ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$USER_NAME"

if [[ -n "$GITHUB_REPO" ]]; then
    echo "-> Cloning user repository..."
    run_in_chroot "su - $USER_NAME -c 'git clone $GITHUB_REPO'"
fi

echo "-> Enabling services..."
for service in "${SERVICES[@]}"; do
    run_in_chroot "systemctl enable $service"
done

rm -f /mnt/root/config.txt

echo "==============================================="
echo "FINISHED!"
echo "==============================================="
echo "Now do:"
echo "  umount -R /mnt"
echo "  reboot"
echo "==============================================="
