#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# proot-setup.sh — Install DroidDesk proot from Docker image

IMAGE="ghcr.io/arinadi/droiddesk:latest"
CONTAINER="droiddesk"
DROIDDESK_DIR="${HOME}/.droiddesk"

echo ">>> Setting up DroidDesk proot..."

# Check if container already exists
if proot-distro list 2>/dev/null | grep -q "$CONTAINER"; then
    echo "  [*] Container '$CONTAINER' already exists."
    echo "  [*] Backing up user data..."
    bash "${DROIDDESK_DIR}/scripts/proot-backup.sh"
    proot-distro remove "$CONTAINER"
fi

echo "  [*] Pulling DroidDesk image (one-time download)..."
proot-distro install "$IMAGE" --name "$CONTAINER"

echo "  [*] Restoring user data..."
bash "${DROIDDESK_DIR}/scripts/proot-restore.sh"

echo "  [+] DroidDesk proot ready."
