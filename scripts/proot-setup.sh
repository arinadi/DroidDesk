#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════
#  DroidDesk proot-setup — Silverblue-style
#  Atomic: keep previous deployment for rollback
# ═══════════════════════════════════════════

IMAGE="ghcr.io/arinadi/droiddesk:latest"
CONTAINER="droiddesk"
PREV_CONTAINER="droiddesk-prev"
CONTAINERS_DIR="/data/data/com.termux/files/usr/var/lib/proot-distro/containers"

echo ">>> Setting up DroidDesk proot..."

# Stage: keep current as "previous" for rollback
if [ -d "${CONTAINERS_DIR}/${CONTAINER}" ]; then
    echo "  [*] Keeping current deployment as rollback backup..."
    if [ -d "${CONTAINERS_DIR}/${PREV_CONTAINER}" ]; then
        proot-distro remove "$PREV_CONTAINER" 2>/dev/null || true
    fi
    mv "${CONTAINERS_DIR}/${CONTAINER}" "${CONTAINERS_DIR}/${PREV_CONTAINER}"
    echo "  [*] Previous deployment saved: $PREV_CONTAINER"
fi

echo "  [*] Pulling DroidDesk image..."
proot-distro install "$IMAGE" --name "$CONTAINER"

echo "  [+] DroidDesk proot ready."
echo "  [+] Rollback available: bash ~/.droiddesk/scripts/proot-rollback.sh"
