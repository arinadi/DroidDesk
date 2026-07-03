#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

DISTRO="ubuntu"
PROOT_USER="admin"
PROOT_PASS="admin"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"

echo ">>> Setting up Ubuntu proot..."

# Install rootfs if not present
if [ ! -d "$ROOTFS" ]; then
    echo "  [*] Installing Ubuntu rootfs (this may take a while)..."
    proot-distro install "$DISTRO"
fi

# Run Ubuntu-side setup
echo "  [*] Bootstrapping Ubuntu packages..."
proot-distro login "$DISTRO" -- bash -c "
    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y -q

    # Install dialog FIRST — prevents freeze on keyboard-configuration/tzdata
    apt-get install -y -q --no-install-recommends dialog

    apt-get upgrade -y -q -o Dpkg::Options::='--force-confold'

    # XFCE + dependencies (minimal, no recommends)
    apt-get install -y -q --no-install-recommends \
        sudo dbus-x11 \
        xfce4-session xfwm4 xfce4-panel xfce4-terminal \
        xfce4-settings xfconf thunar xfdesktop4 \
        fonts-noto pulseaudio-utils libgl1 mesa-utils \
        netcat-openbsd python3-tk

    # User setup
    id ${PROOT_USER} &>/dev/null || useradd -m -s /bin/bash ${PROOT_USER}
    echo \"${PROOT_USER}:${PROOT_PASS}\" | chpasswd
    echo \"${PROOT_USER} ALL=(ALL:ALL) NOPASSWD: ALL\" > /etc/sudoers.d/${PROOT_USER}
    chmod 0440 /etc/sudoers.d/${PROOT_USER}

    # Bash config
    cat > /home/${PROOT_USER}/.bashrc << 'BASHEOF'
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp

# Clean PATH from Termux pollution
export PATH=/home/admin/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# NVM Initialization (if exists)
export NVM_DIR=\"\$HOME/.config/nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"

alias update='sudo apt-get update && sudo apt-get upgrade -y'

# Termux:API Aliases
TAPI_CMDS=\"battery-status notification toast vibrate volume-get volume-set brightness wallpaper\"
for cmd in \$TAPI_CMDS; do
    alias termux-\$cmd=\"tapi termux-\$cmd\"
done
BASHEOF

    # PulseAudio TCP client config
    mkdir -p /home/${PROOT_USER}/.pulse
    cat > /home/${PROOT_USER}/.pulse/client.conf << 'PULSEEOF'
default-server = 127.0.0.1
autospawn = no
daemon-binary = /bin/true
PULSEEOF

    # Android storage symlinks
    echo \"  [*] Setting up Android storage symlinks...\"
    sudo -u ${PROOT_USER} mkdir -p /home/${PROOT_USER}/storage
    sudo -u ${PROOT_USER} ln -sf /sdcard/Download /home/${PROOT_USER}/Downloads
    sudo -u ${PROOT_USER} ln -sf /sdcard/DCIM/Camera /home/${PROOT_USER}/Pictures
    sudo -u ${PROOT_USER} ln -sf /sdcard /home/${PROOT_USER}/Android_Internal

    chown -R ${PROOT_USER}:${PROOT_USER} /home/${PROOT_USER}
" || {
    echo "ERROR: Ubuntu setup failed. Check network and disk space."
    exit 1
}

echo "  [+] Ubuntu proot setup complete."
