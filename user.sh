#!/bin/bash
# user.sh - Setup user

set -euo pipefail

source config.sh

echo "-> Creating user $USER_NAME..."
useradd -m -d "$HOME_DIR" -s /bin/bash "$USER_NAME"
echo "$USER_NAME:$USER_PASSWORD" | chpasswd
echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME
