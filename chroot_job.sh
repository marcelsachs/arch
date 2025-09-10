#!/bin/bash
# chroot_job.sh - Run chroot steps in order

set -euo pipefail

source config.sh

source network.sh
source system_config.sh
source bootloader.sh
source user.sh
source services.sh

if [[ -n "$GITHUB_REPO" ]]; then
    source clone_repo.sh
fi
