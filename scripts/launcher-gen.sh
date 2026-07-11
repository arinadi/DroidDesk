#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Installing launchers..."
DROIDDESK_DIR="$HOME/.arinanox"
mkdir -p ~/.shortcuts

# Remove old launchers (v1 + v2)
rm -f ~/.shortcuts/{start,stop,update}{,-x11,-xfce,-arinanox,-proot}.sh 2>/dev/null || true
rm -f ~/.shortcuts/kill-{x11,proot,all}.sh 2>/dev/null || true
rm -f ~/{start,stop,update}{,-x11,-xfce,-arinanox}.sh 2>/dev/null || true
rm -f ~/kill-{x11,proot,all}.sh 2>/dev/null || true

# Install branded shortcuts (ordered)
cp "${DROIDDESK_DIR}/launchers/stop.sh"   ~/.shortcuts/0-stop-arinanox.sh
cp "${DROIDDESK_DIR}/launchers/start.sh"  ~/.shortcuts/1-start-arinanox.sh
cp "${DROIDDESK_DIR}/launchers/update.sh" ~/.shortcuts/2-update-arinanox.sh
chmod +x ~/.shortcuts/0-stop-arinanox.sh
chmod +x ~/.shortcuts/1-start-arinanox.sh
chmod +x ~/.shortcuts/2-update-arinanox.sh

# Home convenience symlinks
ln -sf ~/.shortcuts/0-stop-arinanox.sh   ~/stop.sh
ln -sf ~/.shortcuts/1-start-arinanox.sh  ~/start.sh
ln -sf ~/.shortcuts/2-update-arinanox.sh ~/update.sh

echo ">>> Launchers installed."
