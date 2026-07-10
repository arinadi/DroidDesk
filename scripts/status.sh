#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════
#  arinanoX Status — Silverblue-style system overview
#  Usage: bash ~/.arinanox/scripts/status.sh
# ═══════════════════════════════════════════

DROIDDESK_DIR="$HOME/.arinanox"
CONTAINER="arinanox"
PREV_CONTAINER="arinanox-prev"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/${CONTAINER}/rootfs"

echo "╔═══════════════════════════════════════╗"
echo "║  📱 arinanoX System Status           ║"
echo "╠═══════════════════════════════════════╣"

# Version
if [ -f "$DROIDDESK_DIR/version.txt" ]; then
    echo "║  Version:  v$(cat $DROIDDESK_DIR/version.txt | tr -d '[:space:]')"
fi

# Current deployment
if [ -d "$ROOTFS" ]; then
    SIZE=$(du -sh "$ROOTFS" 2>/dev/null | cut -f1)
    echo "║  Current:  arinanox ($SIZE)"
else
    echo "║  Current:  NOT INSTALLED"
fi

# Rollback deployment
PREV_ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/containers/${PREV_CONTAINER}/rootfs"
if [ -d "$PREV_ROOTFS" ]; then
    SIZE=$(du -sh "$PREV_ROOTFS" 2>/dev/null | cut -f1)
    echo "║  Rollback: arinanox-prev ($SIZE)"
fi

echo "╠═══════════════════════════════════════╣"

# Running status
if pgrep -f "xfce4-session" > /dev/null 2>&1; then
    echo "║  ● XFCE session running"
else
    echo "║  ○ XFCE not running"
fi

if pgrep -f "termux.x11" > /dev/null 2>&1; then
    echo "║  ● X11 server running"
else
    echo "║  ○ X11 server not running"
fi

echo "╠═══════════════════════════════════════╣"

# Layered packages
if [ -f "$DROIDDESK_DIR/layers.txt" ]; then
    COUNT=$(wc -l < "$DROIDDESK_DIR/layers.txt")
    echo "║  Layered:  $COUNT packages"
    echo "║  (bash ~/.arinanox/scripts/patch.sh)"
else
    echo "║  Layered:  0 (use patch.sh to add)"
fi

# Disk usage
BACKUP_DIR="$DROIDDESK_DIR/backups"
if [ -d "$BACKUP_DIR" ]; then
    BACKUP_COUNT=$(ls "$BACKUP_DIR"/home-*.tar.gz 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt 0 ]; then
        BACKUP_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
        echo "║  Backups:  ${BACKUP_COUNT} snapshots ($BACKUP_SIZE)"
    fi
fi

echo "╚═══════════════════════════════════════╝"
echo ""
echo "  Update:  bash ~/update.sh"
echo "  Rollback: bash ~/.arinanox/scripts/proot-rollback.sh"
echo "  Status:  bash ~/.arinanox/scripts/status.sh"
