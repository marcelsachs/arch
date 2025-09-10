#!/bin/bash
# clone_repo.sh - Clone GitHub repo (optional)

set -euo pipefail

source config.sh

echo "-> Cloning user repository..."
su - $USER_NAME -c 'git clone $GITHUB_REPO'
