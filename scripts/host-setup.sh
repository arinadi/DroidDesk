#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Installing host packages..."

# Skip termux-setup-storage if ~/storage already exists
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
else
    echo "  [*] ~/storage already exists, skipping."
fi

pkg update -y
pkg install -y x11-repo tur-repo
# GPU: virglrenderer (ANGLE path) + virglrenderer-android (fallback)
# snapshot/backup: rsync for hardlink snapshots
# python3: manifest parsing (already included, just ensure)
pkg install -y termux-x11-nightly proot-distro pulseaudio xorg-xrandr netcat-openbsd termux-api \
              virglrenderer virglrenderer-android angle-android \
              rsync python3
echo ">>> Host packages installed."
