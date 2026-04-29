#!/data/data/com.termux/files/usr/bin/bash
# proot-xfce-setup.sh v6.0 (Audio Focused, No GPU)
# Fixed: variable expansion, dialog, apt-get, --no-install-recommends,
#        launcher escaping, error handling
set -euo pipefail

# --- Configuration ---
DISTRO="ubuntu"
PROOT_USER="admin"
PROOT_PASS="admin"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"

# =============================================
#  Step 1/3: Termux Host Setup
# =============================================
echo ">>> 1/3: Termux Host Setup..."
pkg update -y
pkg install -y x11-repo tur-repo
pkg install -y termux-x11-nightly proot-distro pulseaudio xorg-xrandr

# =============================================
#  Step 2/3: Ubuntu Distro Setup
# =============================================
echo ">>> 2/3: Ubuntu Distro Setup..."
if [ ! -d "$ROOTFS" ]; then
    echo "  [*] Installing Ubuntu rootfs (this may take a while)..."
    proot-distro install "$DISTRO"
fi

# Run Ubuntu-side setup
# NOTE: Using double quotes for the bash -c string so that $PROOT_USER
# and $PROOT_PASS are expanded by the HOST shell before being sent to proot.
# Inner heredocs use 'EOF' (single-quoted) to prevent double-expansion.
echo "  [*] Bootstrapping Ubuntu packages..."
proot-distro login "$DISTRO" -- bash -c "
    export DEBIAN_FRONTEND=noninteractive

    # Update package lists
    apt-get update -y -q

    # Install dialog FIRST — prevents freeze on keyboard-configuration/tzdata
    # prompts that need a dialog backend even under noninteractive mode
    apt-get install -y -q --no-install-recommends dialog

    # Upgrade existing packages
    apt-get upgrade -y -q -o Dpkg::Options::='--force-confold'

    # Install XFCE + dependencies (minimal set, no recommends)
    apt-get install -y -q --no-install-recommends \
        sudo dbus-x11 \
        xfce4-session xfwm4 xfce4-panel xfce4-terminal \
        xfce4-settings xfconf thunar \
        fonts-noto pulseaudio-utils

    # --- User Setup ---
    id ${PROOT_USER} &>/dev/null || useradd -m -s /bin/bash ${PROOT_USER}
    echo \"${PROOT_USER}:${PROOT_PASS}\" | chpasswd
    echo \"${PROOT_USER} ALL=(ALL:ALL) NOPASSWD: ALL\" > /etc/sudoers.d/${PROOT_USER}
    chmod 0440 /etc/sudoers.d/${PROOT_USER}

    # --- Bash Config ---
    cat > /home/${PROOT_USER}/.bashrc << 'BASHEOF'
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp
alias update='sudo apt-get update && sudo apt-get upgrade -y'
BASHEOF

    # --- PulseAudio Client Config (Unix Socket) ---
    mkdir -p /home/${PROOT_USER}/.pulse
    cat > /home/${PROOT_USER}/.pulse/client.conf << 'PULSEEOF'
default-server = unix:/tmp/pulse-socket
autospawn = no
daemon-binary = /bin/true
PULSEEOF

    chown -R ${PROOT_USER}:${PROOT_USER} /home/${PROOT_USER}
" || {
    echo "ERROR: Ubuntu setup failed. Check network and disk space."
    exit 1
}
echo "  [+] Ubuntu setup complete."

# =============================================
#  Step 3/3: Generating Launchers
# =============================================
echo ">>> 3/3: Generating Optimized Launchers..."

# --- Launcher 1: X11 & Audio Server (Termux Side) ---
# Single-quoted heredoc ('EOF') — nothing is expanded at generation time.
cat > ~/start-x11.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
PULSE_SOCK="${TERMUX_TMP}/pulse-socket"

echo ">>> Cleaning up old sessions..."
pkill -9 -f "termux-x11|pulseaudio" 2>/dev/null || true
rm -f /tmp/.X0-lock "${TERMUX_TMP}/.X11-unix/X0" 2>/dev/null
rm -f "$PULSE_SOCK" 2>/dev/null
sleep 1

# Start PulseAudio with Unix Socket for high fidelity and low latency
echo ">>> Starting PulseAudio..."
pulseaudio --start --exit-idle-time=-1 \
    --load="module-native-protocol-unix socket=${PULSE_SOCK}"

# Start X11
echo ">>> Starting Termux-X11..."
termux-x11 :0 -ac &
sleep 2

echo ""
echo ">>> X11/High-Fidelity Audio Ready."
echo ">>> Open Termux:X11 app, then run: bash ~/start-xfce.sh"
EOF

# --- Launcher 2: XFCE Desktop (Proot Side) ---
# Double-quoted heredoc — $DISTRO and $PROOT_USER are baked in at generation.
# Runtime variables use \$ to defer expansion.
cat > ~/start-xfce.sh << XFCEOF
#!/data/data/com.termux/files/usr/bin/bash
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
X11_SOCK="\${TERMUX_TMP}/.X11-unix"
PULSE_SOCK="\${TERMUX_TMP}/pulse-socket"

# Build bind mounts
BINDS=""
[ -d "\$X11_SOCK" ]   && BINDS="\$BINDS --bind \$X11_SOCK:/tmp/.X11-unix"
[ -e "\$PULSE_SOCK" ] && BINDS="\$BINDS --bind \$PULSE_SOCK:/tmp/pulse-socket"

echo ">>> Starting XFCE Desktop..."
proot-distro login ${DISTRO} \$BINDS -- su - ${PROOT_USER} -c "
    # Safe Cleanup
    pkill -9 -f 'xfce4|dbus|thunar' 2>/dev/null || true
    rm -rf /tmp/.X* /tmp/dbus-* /tmp/ssh-* 2>/dev/null
    rm -rf ~/.cache/sessions/* 2>/dev/null

    # Export display
    export DISPLAY=:0
    export XDG_RUNTIME_DIR=/tmp

    # Start fresh session
    dbus-run-session startxfce4
"
XFCEOF

chmod +x ~/start-x11.sh ~/start-xfce.sh

echo ""
echo "=========================================="
echo " SETUP COMPLETE (Audio Optimized, v6.0)"
echo ""
echo " Usage:"
echo "   1. bash ~/start-x11.sh"
echo "   2. Open Termux:X11 app"
echo "   3. bash ~/start-xfce.sh  (in new tab)"
echo ""
echo " User: ${PROOT_USER} / Pass: ${PROOT_PASS}"
echo "=========================================="
