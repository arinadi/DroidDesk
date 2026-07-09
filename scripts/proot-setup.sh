#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# proot-setup.sh — Install DroidDesk proot from Docker image (fresh)

IMAGE="ghcr.io/arinadi/droiddesk:latest"
CONTAINER="droiddesk"
CONTAINERS_DIR="/data/data/com.termux/files/usr/var/lib/proot-distro/containers"

echo ">>> Setting up DroidDesk proot..."

# Remove existing container (clean fresh install)
if [ -d "${CONTAINERS_DIR}/${CONTAINER}" ]; then
    echo "  [*] Removing existing container..."
    proot-distro remove "$CONTAINER"
fi

echo "  [*] Pulling DroidDesk image (one-time download)..."
proot-distro install "$IMAGE" --name "$CONTAINER"

echo "  [+] DroidDesk proot ready."

# ─── Optional: manual backup/restore ───
# To preserve your packages before reinstall:
#   bash ~/.droiddesk/scripts/proot-backup.sh
#   bash ~/.droiddesk/scripts/proot-restore.sh
