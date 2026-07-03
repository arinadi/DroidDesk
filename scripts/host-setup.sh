#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Installing host packages..."
termux-setup-storage
pkg update -y
pkg install -y x11-repo tur-repo
pkg install -y termux-x11-nightly proot-distro pulseaudio xorg-xrandr netcat-openbsd termux-api
echo ">>> Host packages installed."
