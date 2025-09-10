#!/bin/bash
# mirrors.sh - Update mirrorlist

set -euo pipefail

source config.sh

echo "-> Updating mirrorlist..."
reflector --country "$COUNTRY" --latest 10 --fastest 5 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
