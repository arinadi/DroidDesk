#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ═══════════════════════════════════════════
#  arinanoX proot-setup — Silverblue-style
#  Atomic: keep previous deployment for rollback
# ═══════════════════════════════════════════

IMAGE="ghcr.io/arinadi/arinanox:latest"
CONTAINER="arinanox"
PREV_CONTAINER="arinanox-prev"
CONTAINERS_DIR="/data/data/com.termux/files/usr/var/lib/proot-distro/containers"

echo ">>> Setting up arinanoX proot..."

# Stage: keep current as "previous" for rollback
if [ -d "${CONTAINERS_DIR}/${CONTAINER}" ]; then
    echo "  [*] Keeping current deployment as rollback backup..."
    if [ -d "${CONTAINERS_DIR}/${PREV_CONTAINER}" ]; then
        proot-distro remove "$PREV_CONTAINER" 2>/dev/null || true
    fi
    mv "${CONTAINERS_DIR}/${CONTAINER}" "${CONTAINERS_DIR}/${PREV_CONTAINER}"
    echo "  [*] Previous deployment saved: $PREV_CONTAINER"
fi

echo "  [*] Pulling arinanoX image..."
proot-distro install "$IMAGE" --name "$CONTAINER"

echo "  [+] arinanoX proot ready."
echo "  [+] Rollback available: bash ~/.arinanox/scripts/proot-rollback.sh"
