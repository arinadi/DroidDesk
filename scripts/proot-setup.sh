#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# proot-setup.sh — Install DroidDesk proot from Docker image
# Uses pre-built OCI image for fast install (~30s vs 5-10min apt-get)

IMAGE="ghcr.io/arinadi/droiddesk:latest"
CONTAINER="droiddesk"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${CONTAINER}"
DROIDDESK_DIR="${HOME}/.droiddesk"

echo ">>> Setting up DroidDesk proot..."

if [ -d "$ROOTFS" ]; then
    echo "  [*] Existing container found. Backing up user data..."
    bash "${DROIDDESK_DIR}/scripts/proot-backup.sh"
    proot-distro remove "$CONTAINER"
fi

echo "  [*] Pulling DroidDesk image (one-time download)..."
proot-distro install "$IMAGE" --name "$CONTAINER"

echo "  [*] Restoring user data..."
bash "${DROIDDESK_DIR}/scripts/proot-restore.sh"

echo "  [+] DroidDesk proot ready."
