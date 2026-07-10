#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Installing launchers..."
DROIDDESK_DIR="$HOME/.arinanox"
mkdir -p ~/.shortcuts

for f in start-x11.sh start-xfce.sh kill-x11.sh kill-proot.sh kill-all.sh update.sh; do
    cp "${DROIDDESK_DIR}/launchers/${f}" ~/.shortcuts/"${f}"
    chmod +x ~/.shortcuts/"${f}"
    ln -sf ~/.shortcuts/"${f}" ~/"${f}"
done

# Legacy shortcut (Termux:Widget reads ~/.shortcuts/)
ln -sf update.sh ~/.shortcuts/update-arinanox.sh 2>/dev/null || true
# Legacy symlink in home dir
ln -sf ~/update.sh ~/update-arinanox.sh 2>/dev/null || true

echo ">>> Launchers installed."
