#!/bin/bash
# services.sh - Enable services

set -euo pipefail

source config.sh

echo "-> Enabling services..."
for service in "${SERVICES[@]}"; do
    systemctl enable $service
done
