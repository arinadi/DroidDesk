#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — User Snapshot
# rsync --link-dest hardlinked snapshots of /home/admin
# Usage: arinanox snapshot create|list|restore <id>
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

SNAPSHOT_DIR="$HOME/.arinanox/snapshots"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/arinanox/rootfs"
HOME_SRC="$ROOTFS/home/admin"
MAX_SNAPSHOTS=3

CMD="${1:-list}"
SNAP_ID="${2:-}"

# ── create ───────────────────────────────────────────────────
do_create() {
    # Generate manifest first
    if [ -f "$HOME/.arinanox/scripts/manifest-generate.sh" ]; then
        echo ">>> Generating manifest..."
        bash "$HOME/.arinanox/scripts/manifest-generate.sh" 2>/dev/null || true
    fi
    
    # Create hardlinked snapshot
    TS=$(date +%Y%m%d-%H%M%S)
    SNAP_PATH="$SNAPSHOT_DIR/$TS"
    
    mkdir -p "$SNAPSHOT_DIR"
    
    # Find last snapshot for --link-dest
    LINK_DEST=""
    LAST=$(ls -1t "$SNAPSHOT_DIR" 2>/dev/null | head -1)
    if [ -n "$LAST" ] && [ -d "$SNAPSHOT_DIR/$LAST" ]; then
        LINK_DEST="--link-dest=$SNAPSHOT_DIR/$LAST"
    fi
    
    echo ">>> Creating snapshot: $TS"
    rsync -a $LINK_DEST "$HOME_SRC/" "$SNAP_PATH/" 2>&1 | tail -2
    
    # Update "current" symlink
    rm -f "$HOME/.arinanox/snapshot-current"
    ln -sf "$SNAP_PATH" "$HOME/.arinanox/snapshot-current"
    
    # Rotate: keep only last N
    COUNT=$(ls -1t "$SNAPSHOT_DIR" 2>/dev/null | wc -l)
    if [ "$COUNT" -gt "$MAX_SNAPSHOTS" ]; then
        ls -1t "$SNAPSHOT_DIR" | tail -n +$((MAX_SNAPSHOTS + 1)) | while read old; do
            echo "  → removing old: $old"
            rm -rf "$SNAPSHOT_DIR/$old"
        done
    fi
    
    echo "  ✓ Snapshot created ($(du -sh "$SNAP_PATH" | awk '{print $1}'))"
}

# ── list ─────────────────────────────────────────────────────
do_list() {
    echo "Snapshots:"
    echo ""
    if [ ! -d "$SNAPSHOT_DIR" ] || [ -z "$(ls -A "$SNAPSHOT_DIR" 2>/dev/null)" ]; then
        echo "  (none)"
    else
        ls -1t "$SNAPSHOT_DIR" | head -"$MAX_SNAPSHOTS" | while read snap; do
            SIZE=$(du -sh "$SNAPSHOT_DIR/$snap" 2>/dev/null | awk '{print $1}')
            echo "  $snap   ($SIZE)"
        done
    fi
    echo ""
    echo "Current → $([ -L "$HOME/.arinanox/snapshot-current" ] && basename "$(readlink "$HOME/.arinanox/snapshot-current")" || echo "none")"
}

# ── restore ──────────────────────────────────────────────────
do_restore() {
    if [ -z "$SNAP_ID" ]; then
        echo "Usage: arinanox snapshot restore <snapshot-id>"
        do_list
        exit 1
    fi
    
    SNAP_PATH="$SNAPSHOT_DIR/$SNAP_ID"
    if [ ! -d "$SNAP_PATH" ]; then
        echo "✗ Snapshot not found: $SNAP_ID"
        do_list
        exit 1
    fi
    
    echo ">>> Restoring snapshot: $SNAP_ID"
    echo "    ⚠ This will overwrite /home/admin."
    read -p "    Continue? [y/N] " confirm
    case "$confirm" in [yY]*) ;; *) echo "    Cancelled."; exit 0 ;; esac
    
    rsync -a --delete "$SNAP_PATH/" "$HOME_SRC/" 2>&1 | tail -2
    ln -sf "$SNAP_PATH" "$HOME/.arinanox/snapshot-current"
    echo "  ✓ Restored to $SNAP_ID"
    echo "  Restart desktop to apply: arinanox stop && arinanox start"
}

# ── Dispatch ─────────────────────────────────────────────────
case "$CMD" in
    create|c) do_create ;;
    list|ls|l)  do_list ;;
    restore|r)  do_restore ;;
    *)
        echo "Usage: arinanox snapshot create|list|restore <id>"
        exit 1
        ;;
esac
