#!/bin/bash
# network.sh - Setup network configuration

set -euo pipefail

source config.sh

echo "-> Configuring network..."
cat << EOF > /etc/systemd/network/20-wired.network
[Match]
Name=en* eth*

[Network]
DHCP=yes
EOF
cat << EOF > /etc/systemd/network/25-wireless.network
[Match]
Name=wl*

[Network]
DHCP=yes
EOF
