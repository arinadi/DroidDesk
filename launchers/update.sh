#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
REPO="https://raw.githubusercontent.com/arinadi/DroidDesk/main"
DROIDDESK_DIR="$HOME/.droiddesk"
CACHE_BUST="?v=$(date +%s)"

echo ">>> Checking for updates..."
REMOTE_VER=$(curl -sL "${REPO}/version.txt${CACHE_BUST}" | tr -d '[:space:]')

if [ -f "$DROIDDESK_DIR/version.txt" ]; then
    LOCAL_VER=$(cat "$DROIDDESK_DIR/version.txt" | tr -d '[:space:]')
    if [ "$REMOTE_VER" = "$LOCAL_VER" ]; then
        echo ">>> DroidDesk is up to date (v${LOCAL_VER})."
        exit 0
    fi
    echo ">>> Update available: v${LOCAL_VER} → v${REMOTE_VER}"
else
    echo ">>> Fresh install: v${REMOTE_VER}"
fi

curl -sL "${REPO}/bootstrap.sh${CACHE_BUST}" | bash
