#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
REPO="https://raw.githubusercontent.com/arinadi/DroidDesk/main"
DROIDDESK_DIR="$HOME/.droiddesk"

echo ">>> Checking for updates..."
REMOTE_VER=$(curl -sL --retry 2 "${REPO}/version.txt" 2>/dev/null | tr -d '[:space:]')

if [ -f "$DROIDDESK_DIR/version.txt" ]; then
    LOCAL_VER=$(cat "$DROIDDESK_DIR/version.txt" | tr -d '[:space:]')
    if [ "$REMOTE_VER" = "$LOCAL_VER" ]; then
        echo ">>> DroidDesk is up to date (v${LOCAL_VER})."
        exit 0
    fi
    echo ">>> Update available: v${LOCAL_VER} → v${REMOTE_VER}"
    echo ""
    echo ">>> Reinstalling DroidDesk (fresh image)..."
else
    echo ">>> Fresh install: v${REMOTE_VER}"
fi

# Re-run bootstrap (downloads latest scripts, installs fresh image)
curl -sL --retry 2 "${REPO}/bootstrap.sh" | bash
