#!/bin/bash
# main.sh - Orchestrator script to run the installation

set -euo pipefail

source config.sh

echo "==============================================="
echo "Arch Linux Installation"
echo "==============================================="
echo "Disk: $DISK"
echo "Hostname: $HOSTNAME"
echo "User: $USER_NAME"
echo "Timezone: $TIMEZONE"
echo "==============================================="
echo "WARNING: WILL WIPE $DISK"
echo "Type 'yes' to continue:"
read -r confirm
[[ "$confirm" == "yes" ]] || { echo "Installation cancelled."; exit 1; }

source disk.sh
source mirrors.sh
source base_install.sh

cp config.sh chroot_job.sh network.sh system_config.sh bootloader.sh user.sh services.sh clone_repo.sh /mnt/root/

arch-chroot /mnt /root/chroot_job.sh

rm -f /mnt/root/config.sh /mnt/root/*.sh

echo "==============================================="
echo "FINISHED!"
echo "==============================================="
echo "Now do:"
echo " umount -R /mnt"
echo " reboot"
echo "==============================================="
