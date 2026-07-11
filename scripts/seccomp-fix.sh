#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Seccomp Mitigation
# PROOT_NO_SECCOMP=1 disables proot's own seccomp filter,
# letting Android's seccomp-bpf handle syscalls directly.
# Tradeoff: less isolation inside proot, but proot already
# runs as non-root user — acceptable in most cases.
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

ARINANOX_DIR="$HOME/.arinanox"
PROFILE="$HOME/.bashrc"

echo ">>> seccomp-fix: applying PROOT_NO_SECCOMP=1"

# ── Patch start.sh ──────────────────────────────────────────
START_SH="$HOME/.shortcuts/1-start-arinanox.sh"
if [ -f "$START_SH" ]; then
    # Add PROOT_NO_SECCOMP=1 to proot-distro login line
    if ! grep -q "PROOT_NO_SECCOMP" "$START_SH"; then
        echo "  → patching $START_SH"
        sed -i 's|proot-distro login arinanox|PROOT_NO_SECCOMP=1 proot-distro login arinanox|g' "$START_SH"
        echo "  ✓ start.sh patched"
    else
        echo "  ✓ start.sh already patched"
    fi
fi

# Also patch source in launchers dir
START_SRC="$ARINANOX_DIR/launchers/start.sh"
if [ -f "$START_SRC" ] && ! grep -q "PROOT_NO_SECCOMP" "$START_SRC"; then
    sed -i 's|proot-distro login arinanox|PROOT_NO_SECCOMP=1 proot-distro login arinanox|g' "$START_SRC"
fi

# ── Patch profile ───────────────────────────────────────────
if ! grep -q "PROOT_NO_SECCOMP" "$PROFILE" 2>/dev/null; then
    echo "" >> "$PROFILE"
    echo "# arinanoX: Android 15+ seccomp mitigation" >> "$PROFILE"
    echo "export PROOT_NO_SECCOMP=1" >> "$PROFILE"
    echo "  ✓ profile patched"
else
    echo "  ✓ profile already patched"
fi

echo ">>> Done. Restart: bash ~/stop.sh && bash ~/start.sh"
