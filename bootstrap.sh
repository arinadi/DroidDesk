#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ══════════════════════════════════════════
#  DroidDesk Bootstrap — curl | bash installer
#  https://github.com/arinadi/DroidDesk
# ══════════════════════════════════════════

REPO="https://raw.githubusercontent.com/arinadi/DroidDesk/main"
DROIDDESK_DIR="$HOME/.droiddesk"
SCRIPTS_DIR="${DROIDDESK_DIR}/scripts"
LAUNCHERS_DIR="${DROIDDESK_DIR}/launchers"
CACHE_BUST="?v=$(date +%s)"

mkdir -p "$SCRIPTS_DIR" "$LAUNCHERS_DIR"

# --- Version Check ---
REMOTE_VER=$(curl -sL "${REPO}/version.txt${CACHE_BUST}" | tr -d '[:space:]')
if [ -z "$REMOTE_VER" ]; then
    echo "ERROR: Could not fetch version. Check your internet connection."
    exit 1
fi

if [ -f "$DROIDDESK_DIR/version.txt" ]; then
    LOCAL_VER=$(cat "$DROIDDESK_DIR/version.txt" | tr -d '[:space:]')
    echo ""
    echo "=========================================="
    echo " 📱 DroidDesk v${LOCAL_VER} detected"
    echo "    Latest version: v${REMOTE_VER}"
    echo "=========================================="
    echo ""
    echo "  [1] Update to v${REMOTE_VER}"
    echo "  [2] Fresh install (wipe & reinstall)"
    echo "  [3] Cancel"
    echo ""
    read -rp "  Choose [1/2/3]: " CHOICE

    case "$CHOICE" in
        1)
            if [ "$REMOTE_VER" = "$LOCAL_VER" ]; then
                echo ">>> Already up to date (v${LOCAL_VER})."
                exit 0
            fi
            echo ">>> Updating: v${LOCAL_VER} → v${REMOTE_VER}"
            ;;
        2)
            echo ">>> Fresh install: wiping ~/.droiddesk..."
            rm -rf "$DROIDDESK_DIR"
            mkdir -p "$SCRIPTS_DIR" "$LAUNCHERS_DIR"
            ;;
        3|*)
            echo ">>> Cancelled."
            exit 0
            ;;
    esac
else
    echo ">>> Installing DroidDesk v${REMOTE_VER}..."
fi

# --- Download Scripts ---
echo ">>> Downloading scripts..."
for f in host-setup.sh proot-setup.sh api-bridge-setup.sh xfce-config.sh \
         launcher-gen.sh motd-setup.sh tui-installer.sh; do
    curl -sL "${REPO}/scripts/${f}${CACHE_BUST}" -o "${SCRIPTS_DIR}/${f}"
    chmod +x "${SCRIPTS_DIR}/${f}"
done

# --- Download Launchers ---
echo ">>> Downloading launchers..."
for f in start-x11.sh start-xfce.sh kill-x11.sh kill-proot.sh kill-all.sh update.sh; do
    curl -sL "${REPO}/launchers/${f}${CACHE_BUST}" -o "${LAUNCHERS_DIR}/${f}"
    chmod +x "${LAUNCHERS_DIR}/${f}"
done

# --- Download hardened API bridge ---
echo ">>> Downloading API bridge..."
curl -sL "${REPO}/run-api-bridge.sh${CACHE_BUST}" -o "${DROIDDESK_DIR}/run-api-bridge.sh"
chmod +x "${DROIDDESK_DIR}/run-api-bridge.sh"

# --- Execute Setup ---
echo ""
echo ">>> Running host setup..."
bash "${SCRIPTS_DIR}/host-setup.sh"

echo ""
echo ">>> Setting up Ubuntu proot..."
bash "${SCRIPTS_DIR}/proot-setup.sh"

echo ""
echo ">>> Setting up Termux:API bridge..."
bash "${SCRIPTS_DIR}/api-bridge-setup.sh"

echo ""
echo ">>> Applying XFCE mobile theme..."
bash "${SCRIPTS_DIR}/xfce-config.sh"

echo ""
echo ">>> Installing launchers..."
bash "${SCRIPTS_DIR}/launcher-gen.sh"

echo ""
echo ">>> Setting up MOTD..."
bash "${SCRIPTS_DIR}/motd-setup.sh"

# --- Save Version ---
echo "$REMOTE_VER" > "$DROIDDESK_DIR/version.txt"

echo ""
echo "=========================================="
echo " ✅ DroidDesk v${REMOTE_VER} setup complete!"
echo ""
echo " Start:"
echo "   1. bash ~/start-x11.sh"
echo "   2. Open Termux:X11 app"
echo "   3. bash ~/start-xfce.sh  (in new tab)"
echo ""
echo " Stop/Update:"
echo "   bash ~/kill-all.sh         (stop ALL)"
echo "   bash ~/update.sh           (update DroidDesk)"
echo "   bash ~/.droiddesk/scripts/tui-installer.sh  (install extra apps)"
echo "=========================================="
