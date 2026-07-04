#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# patch-firefox.sh — Install Firefox ESR into DroidDesk proot
# Run after install: bash ~/.droiddesk/scripts/patch-firefox.sh

CONTAINER="droiddesk"

echo ">>> Installing Firefox ESR in proot..."
proot-distro login "$CONTAINER" -- bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q
    apt-get install -y -q firefox-esr
    apt-get clean
    rm -rf /var/lib/apt/lists/*
"

echo ">>> Firefox ESR installed."
echo ">>> Launch: proot-distro login $CONTAINER -- firefox-esr"
