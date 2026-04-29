#!/data/data/com.termux/files/usr/bin/bash
# proot-xfce-setup.sh v2.3
# Install XFCE4 in Ubuntu 22.04 (proot-distro) via Termux-X11
set -uo pipefail

readonly PROOT_DISTRO="ubuntu"
readonly ADMIN_USER="admin"
readonly ADMIN_PASS="admin"
readonly TERMUX_PREFIX="/data/data/com.termux/files/usr"
readonly TERMUX_BIN="${TERMUX_PREFIX}/bin"
TERMUX_TMP="${TMPDIR:-${TERMUX_PREFIX}/tmp}"
readonly TERMUX_VK_ICD="${TERMUX_PREFIX}/share/vulkan/icd.d"
readonly TERMUX_LIB="${TERMUX_PREFIX}/lib"
readonly PROOT_ROOTFS="${TERMUX_PREFIX}/var/lib/proot-distro/installed-rootfs/${PROOT_DISTRO}"
readonly PROOT_HOME="${PROOT_ROOTFS}/home/${ADMIN_USER}"

TOTAL_STEPS=8
CURRENT_STEP=0
GPU_MODE="zink"

# Colors for basic status
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' W='\033[1;37m' D='\033[0;90m'
P='\033[0;35m' N='\033[0m'

# --- Progress ---
progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n${C}>>> [STEP ${CURRENT_STEP}/${TOTAL_STEPS}]${N}"
}

# --- Termux pkg install ---
tpkg() {
    echo -e "${C}[Termux] Installing: $1${N}"
    "${TERMUX_BIN}/pkg" install -y "$1"
}

# --- Ubuntu: run command with RAW output ---
ubuntu_run() {
    proot-distro login "${PROOT_DISTRO}" -- \
        env PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
        bash -c "$1"
}

# --- Ubuntu apt install RAW ---
ubuntu_pkg() {
    local pkgs="$1" label="${2:-$1}"
    echo -e "\n${C}[Ubuntu] Installing: ${label}${N}"
    ubuntu_run "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y \
            -o Dpkg::Options::='--force-confold' \
            -o APT::Get::Assume-Yes=true \
            ${pkgs}
    "
}

# --- Header ---
header() {
    echo -e "${C}===================================================="
    echo "  proot-xfce-setup.sh v2.3"
    echo "  Ubuntu 22.04 -> XFCE4 -> Termux-X11"
    echo -e "====================================================${N}"
    echo "  Distro : Ubuntu 22.04 LTS"
    echo "  User   : ${ADMIN_USER} (pass: ${ADMIN_PASS})"
    echo ""
}

# --- Detect GPU ---
detect_device() {
    echo -e "${P}[*] Detecting GPU...${N}"
    local brand gpu_egl
    brand=$(getprop ro.product.brand 2>/dev/null || echo "unknown")
    gpu_egl=$(getprop ro.hardware.egl 2>/dev/null || echo "unknown")
    echo "  Brand: ${brand}  EGL: ${gpu_egl}"

    local is_adreno=false
    [[ "${gpu_egl,,}" == *"adreno"* || "${gpu_egl,,}" == *"freedreno"* ]] && is_adreno=true
    [ -e "/dev/kgsl-3d0" ] && is_adreno=true
    [[ "${brand,,}" =~ ^(xiaomi|redmi|poco|oneplus|motorola|moto|realme|oppo|vivo)$ ]] && is_adreno=true

    if [ "${is_adreno}" = "true" ]; then
        GPU_MODE="turnip"
        echo -e "  GPU: ${G}Adreno detected -> Using Turnip/Vulkan HW accel${N}\n"
    else
        echo -e "  GPU: ${Y}Non-Adreno -> Using Zink/software fallback${N}\n"
    fi
}

# --- Confirmation ---
confirm_start() {
    echo -e "${Y}Components to be installed:${N}"
    echo "  [Termux] termux-x11-nightly, proot-distro, pulseaudio, mesa-zink"
    echo "  [Ubuntu] XFCE4, Firefox, LibreOffice, GIMP, VLC, Python3, NodeJS"
    echo "  [User]   admin / admin (sudo NOPASSWD)"
    echo "  Estimate: ~1.5-2 GB, 10-30 minutes"
    echo ""
    read -rp "  Continue? [Y/n]: " _ans
    [[ "${_ans:-Y}" =~ ^[Nn]$ ]] && echo "Cancelled." && exit 0
    echo ""
}

# STEP 1: Termux Packages
step1_termux_packages() {
    progress
    echo -e "${P}Installing Termux packages...${N}"

    "${TERMUX_BIN}/pkg" update -y
    tpkg "x11-repo"
    tpkg "tur-repo"
    "${TERMUX_BIN}/pkg" update -y
    tpkg "termux-x11-nightly"
    tpkg "xorg-xrandr"
    tpkg "proot-distro"
    tpkg "proot"
    tpkg "pulseaudio"
    tpkg "mesa-zink"
    [ "${GPU_MODE}" = "turnip" ] && tpkg "mesa-vulkan-icd-freedreno"
    tpkg "vulkan-loader-android"
    tpkg "imagemagick"
}

# STEP 2: Install Ubuntu 22.04 Rootfs
step2_install_ubuntu() {
    progress
    echo -e "${P}Installing Ubuntu 22.04 rootfs...${N}"

    if [ -f "${PROOT_ROOTFS}/bin/bash" ]; then
        echo -e "${Y}[!] Ubuntu rootfs already exists, skipping download.${N}"
        return 0
    fi
    echo "Downloading ~400MB rootfs..."
    proot-distro install "${PROOT_DISTRO}"

    if [ ! -f "${PROOT_ROOTFS}/bin/bash" ]; then
        echo -e "\n${R}[X] ERROR: rootfs creation failed. Check connection.${N}"
        exit 1
    fi
    echo -e "${G}[V] Ubuntu rootfs ready.${N}"
}

# STEP 3: Update Ubuntu & Base Dependencies
step3_ubuntu_base() {
    progress
    echo -e "${P}Updating Ubuntu & installing base dependencies...${N}"

    echo "[*] apt update & upgrade..."
    ubuntu_run "
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get upgrade -y -o Dpkg::Options::='--force-confold'
    "

    ubuntu_pkg "sudo" "sudo"
    ubuntu_pkg "curl wget git nano htop unzip ca-certificates" "system utils"
    ubuntu_pkg "dbus dbus-x11" "dbus"
    ubuntu_pkg "x11-apps x11-utils x11-xserver-utils" "X11 utils"
    ubuntu_pkg "libx11-6 libxext6 libxrender1 libxrandr2 libxi6" "X11 libs"
    ubuntu_pkg "libgl1 libgles2 libvulkan1 mesa-utils" "Mesa stubs"
    ubuntu_pkg "pulseaudio-utils" "PulseAudio client"
    ubuntu_pkg "fonts-noto fonts-noto-color-emoji fonts-liberation" "fonts"
}

# STEP 4: Install XFCE4 & Applications
step4_ubuntu_xfce() {
    progress
    echo -e "${P}Installing XFCE4 & Applications...${N}"
    echo -e "${Y}This is the longest step (~1GB). Please wait...${N}"

    ubuntu_pkg \
        "xfce4 xfce4-terminal xfce4-whiskermenu-plugin
         xfce4-notifyd xfce4-screenshooter xfce4-taskmanager" \
        "XFCE4 core"

    ubuntu_pkg \
        "thunar thunar-archive-plugin mousepad ristretto xarchiver" \
        "Thunar + tools"

    ubuntu_pkg "firefox" "Firefox"

    ubuntu_pkg \
        "libreoffice-writer libreoffice-calc libreoffice-impress" \
        "LibreOffice"

    ubuntu_pkg "gimp vlc" "GIMP & VLC"

    ubuntu_pkg \
        "python3 python3-pip python3-venv nodejs npm build-essential git" \
        "Development tools"
}

# STEP 5: Create Admin User
step5_create_admin() {
    progress
    echo -e "${P}Creating user '${ADMIN_USER}'...${N}"

    ubuntu_run "
        export DEBIAN_FRONTEND=noninteractive
        apt-get install -y -q sudo >/dev/null 2>&1

        if id '${ADMIN_USER}' >/dev/null 2>&1; then
            echo 'User already exists'
        else
            useradd -m -s /bin/bash -c 'Administrator' '${ADMIN_USER}'
            echo 'User created'
        fi

        echo '${ADMIN_USER}:${ADMIN_PASS}' | chpasswd
        usermod -aG sudo '${ADMIN_USER}' 2>/dev/null || true
        groupadd -f adm 2>/dev/null || true
        usermod -aG adm  '${ADMIN_USER}' 2>/dev/null || true

        mkdir -p /etc/sudoers.d
        cat > /etc/sudoers.d/admin-nopasswd << 'SUDO_EOF'
Defaults !requiretty
Defaults !env_reset
admin ALL=(ALL:ALL) NOPASSWD: ALL
SUDO_EOF
        chmod 0440 /etc/sudoers.d/admin-nopasswd
        chmod u+s  /usr/bin/sudo 2>/dev/null || true
        mkdir -p '/home/${ADMIN_USER}'
        chown -R '${ADMIN_USER}:${ADMIN_USER}' '/home/${ADMIN_USER}'

        cat > '/home/${ADMIN_USER}/.bashrc' << 'BASH_EOF'
case \$- in *i*) ;; *) return;; esac
export PS1='\[\033[01;32m\]admin@ubuntu\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR=/tmp
alias ll='ls -la --color=auto'
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
[ -f ~/.gpu-env.sh ] && source ~/.gpu-env.sh
BASH_EOF
        chown '${ADMIN_USER}:${ADMIN_USER}' '/home/${ADMIN_USER}/.bashrc'
    "
    echo -e "${G}[V] Admin user ready (sudo NOPASSWD)${N}"
}

# STEP 6: XFCE4 Theme Configuration
step6_xfce_theme() {
    progress
    echo -e "${P}Configuring XFCE4 theme...${N}"

    mkdir -p \
        "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml" \
        "${PROOT_HOME}/.config/autostart" \
        "${PROOT_HOME}/Desktop" \
        "${PROOT_HOME}/Pictures"

    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName"     type="string" value="Adwaita-dark"/>
    <property name="IconThemeName" type="string" value="Adwaita"/>
  </property>
  <property name="Xft" type="empty">
    <property name="DPI"       type="int"    value="96"/>
    <property name="Antialias" type="int"    value="1"/>
    <property name="Hinting"   type="int"    value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA"      type="string" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName"          type="string" value="Noto Sans 11"/>
    <property name="MonospaceFontName" type="string" value="Liberation Mono 10"/>
  </property>
</channel>
EOF

    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme"             type="string" value="Default-xhdpi"/>
    <property name="use_compositing"   type="bool"   value="true"/>
    <property name="frame_opacity"     type="int"    value="95"/>
    <property name="show_frame_shadow" type="bool"   value="true"/>
    <property name="snap_to_border"    type="bool"   value="true"/>
    <property name="tile_on_move"      type="bool"   value="true"/>
    <property name="button_layout"     type="string" value="O|SHMC"/>
  </property>
</channel>
EOF

    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-terminal" version="1.0">
  <property name="color-foreground" type="string" value="#f8f8f2"/>
  <property name="color-background" type="string" value="#282a36"/>
  <property name="color-palette"    type="string"
    value="#21222c;#ff5555;#50fa7b;#f1fa8c;#bd93f9;#ff79c6;#8be9fd;#f8f8f2;#6272a4;#ff6e6e;#69ff94;#ffffa5;#d6acff;#ff92df;#a4ffff;#ffffff"/>
  <property name="font-name"        type="string" value="Liberation Mono 11"/>
  <property name="scrolling-lines"  type="uint"   value="5000"/>
</channel>
EOF

    cat > "${PROOT_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Super&gt;e" type="string" value="thunar"/>
      <property name="&lt;Super&gt;t" type="string" value="xfce4-terminal"/>
      <property name="Print"          type="string" value="xfce4-screenshooter"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Alt&gt;F4"      type="string" value="close_window_key"/>
      <property name="&lt;Super&gt;d"     type="string" value="show_desktop_key"/>
      <property name="&lt;Super&gt;Left"  type="string" value="tile_left_key"/>
      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
      <property name="&lt;Super&gt;Up"    type="string" value="maximize_window_key"/>
    </property>
  </property>
</channel>
EOF

    for f in Terminal Files Firefox; do
        case $f in
            Terminal) exec_="xfce4-terminal"; icon_="utilities-terminal" ;;
            Files)    exec_="thunar";         icon_="folder" ;;
            Firefox)  exec_="firefox %u";    icon_="firefox" ;;
        esac
        cat > "${PROOT_HOME}/Desktop/${f}.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${f}
Exec=${exec_}
Icon=${icon_}
EOF
    done

    local wp_dst="${PROOT_HOME}/Pictures/wallpaper.jpg"
    if command -v convert >/dev/null 2>&1; then
        echo "Generating wallpaper..."
        convert -size 1920x1080 gradient:"#1a1b2e"-"#16213e" "${wp_dst}" 2>/dev/null || true
    fi

    ubuntu_run "chown -R ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}" || true
    echo -e "${G}[V] XFCE4 theme configured: Adwaita-dark + Dracula terminal${N}"
}

# STEP 7: GPU Environment Script
step7_gpu_env() {
    progress
    echo -e "${P}Setting up GPU environment...${N}"

    cat > "${PROOT_HOME}/.gpu-env.sh" << GPUEOF
#!/bin/bash
# ~/.gpu-env.sh — GPU environment for XFCE4

export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export MESA_LOADER_DRIVER_OVERRIDE=zink
export GALLIUM_DRIVER=zink
export MESA_VK_WSI_PRESENT_MODE=immediate
export ZINK_DESCRIPTORS=lazy
export TU_DEBUG=noconform

_VK_TERMUX_DIR="/usr/share/vulkan/icd.d.termux"
if [ -f "\${_VK_TERMUX_DIR}/freedreno_icd.aarch64.json" ]; then
    export VK_ICD_FILENAMES="\${_VK_TERMUX_DIR}/freedreno_icd.aarch64.json"
fi

export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR=/tmp
export XDG_DATA_DIRS=/usr/share:/usr/local/share
GPUEOF

    chmod +x "${PROOT_HOME}/.gpu-env.sh"
    ubuntu_run "chown ${ADMIN_USER}:${ADMIN_USER} /home/${ADMIN_USER}/.gpu-env.sh" || true
    echo -e "${G}[V] ~/.gpu-env.sh ready — mode: ${GPU_MODE}${N}"
}

# STEP 8: Create Launcher Scripts
step8_launchers() {
    progress
    echo -e "${P}Creating launcher scripts...${N}"

    # --- start-x11.sh ---
    {
        cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# start-x11.sh — STEP 1: Start Termux-X11 & PulseAudio
# Run this in a SEPARATE Termux session from start-xfce.sh
# After running, open the Termux:X11 app on Android.
HDR
        cat << VARS
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
VARS
        cat << 'BODY'

echo "[*] Cleaning up old sessions..."
pkill -9 -f "com.termux.x11" 2>/dev/null
pkill -9 -f "termux-x11"     2>/dev/null
pkill -9 -f "pulseaudio"     2>/dev/null
rm -f /tmp/.X0-lock "${TERMUX_TMP}/.X11-unix/X0" 2>/dev/null
sleep 0.5

echo "[*] Starting PulseAudio (Termux)..."
unset PULSE_SERVER
pulseaudio --kill 2>/dev/null; sleep 0.3
pulseaudio --start --exit-idle-time=-1 --daemonize=true \
    --log-target="file:${TERMUX_TMP}/pulseaudio.log" 2>/dev/null
sleep 1
pactl load-module module-native-protocol-tcp \
    auth-ip-acl=127.0.0.1 auth-anonymous=1 2>/dev/null || true
echo "[V] PulseAudio ready (TCP 127.0.0.1)"

echo "[*] Starting Termux-X11 display :0 ..."
termux-x11 :0 -ac &
X11_PID=$!
sleep 2

X11_SOCK="${TERMUX_TMP}/.X11-unix"
if [ ! -S "${X11_SOCK}/X0" ]; then
    echo ""
    echo "[!] ERROR: X11 socket not found: ${X11_SOCK}/X0"
    echo "    Make sure the Termux:X11 app is installed on Android."
    echo "    Try running again after opening the Termux:X11 app."
    kill $X11_PID 2>/dev/null
    exit 1
fi

echo "[V] Termux-X11 running — socket: ${X11_SOCK}/X0"
echo ""
echo "===================================================="
echo " X11 & Audio Ready!"
echo " -> Open Termux:X11 app on Android"
echo " -> In ANOTHER Termux tab, run: bash ~/start-xfce.sh"
echo "===================================================="
echo ""

# Wait for termux-x11
wait $X11_PID
BODY
    } > ~/start-x11.sh
    chmod +x ~/start-x11.sh
    echo "  [V] ~/start-x11.sh created"

    # --- start-xfce.sh ---
    {
        cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# start-xfce.sh — STEP 2: Enter Ubuntu proot -> startxfce4
# Prerequisite: start-x11.sh is already running in another tab
HDR
        cat << VARS
PROOT_DISTRO="${PROOT_DISTRO}"
ADMIN_USER="${ADMIN_USER}"
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
TERMUX_VK_ICD="/data/data/com.termux/files/usr/share/vulkan/icd.d"
TERMUX_LIB="/data/data/com.termux/files/usr/lib"
VARS
        cat << 'BODY'

# Check X11 socket
X11_SOCK="${TERMUX_TMP}/.X11-unix"
if [ ! -S "${X11_SOCK}/X0" ]; then
    echo ""
    echo "[!] X11 socket not found: ${X11_SOCK}/X0"
    echo ""
    echo "Please run this in ANOTHER Termux tab first:"
    echo "  bash ~/start-x11.sh"
    echo ""
    echo "Once 'X11 & Audio Ready!' appears, open Termux:X11"
    echo "app on Android, then run this script again."
    echo ""
    exit 1
fi
echo "[V] X11 socket found"

# Kill old sessions
pkill -9 -f "xfce4-session" 2>/dev/null
pkill -9 -f "dbus-daemon"   2>/dev/null
sleep 0.3

# Bind mounts
BINDS="--bind ${X11_SOCK}:/tmp/.X11-unix"
[ -d "/dev/dri" ]                   && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ]              && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -e "/dev/mali0" ]                 && BINDS="${BINDS} --bind /dev/mali0:/dev/mali0"
[ -d "${TERMUX_VK_ICD}" ]           && BINDS="${BINDS} --bind ${TERMUX_VK_ICD}:/usr/share/vulkan/icd.d.termux"
[ -f "${TERMUX_LIB}/libvulkan.so" ] && \
    BINDS="${BINDS} --bind ${TERMUX_LIB}/libvulkan.so:/usr/lib/aarch64-linux-gnu/libvulkan_termux.so"

echo "[*] Entering Ubuntu -> Logging in as ${ADMIN_USER} -> Starting XFCE4"
echo ""

proot-distro login "${PROOT_DISTRO}" \
    --env DISPLAY=:0 \
    --env PULSE_SERVER=127.0.0.1 \
    --env XDG_RUNTIME_DIR=/tmp \
    ${BINDS} \
    -- bash -c '
        export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        chmod 1777 /tmp 2>/dev/null || true
        mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix 2>/dev/null || true

        if [ ! -S /tmp/.X11-unix/X0 ]; then
            echo "[!] X11 socket bind failed inside Ubuntu"; exit 1
        fi

        su - '"${ADMIN_USER}"' -c "
            [ -f ~/.gpu-env.sh ] && source ~/.gpu-env.sh
            echo \"  GPU : \${GALLIUM_DRIVER:-unset}\"
            echo \"  DISP: \${DISPLAY}\"
            echo \"  AUDIO: \${PULSE_SERVER}\"
            echo \"\"
            exec dbus-run-session -- startxfce4
        "
    '

EXIT_CODE=$?
echo ""
[ ${EXIT_CODE} -eq 0 ] \
    && echo "[V] XFCE4 session ended normally." \
    || echo "[!] XFCE4 exited (rc=${EXIT_CODE})"
echo "Audio log: ${TERMUX_TMP}/pulseaudio.log"
echo ""
BODY
    } > ~/start-xfce.sh
    chmod +x ~/start-xfce.sh
    echo "  [V] ~/start-xfce.sh created"

    # --- shell-ubuntu.sh ---
    {
        cat << 'HDR'
#!/data/data/com.termux/files/usr/bin/bash
# shell-ubuntu.sh — Enter Ubuntu shell as admin
# Use for: apt install, configuration, troubleshooting
HDR
        cat << VARS
PROOT_DISTRO="${PROOT_DISTRO}"
ADMIN_USER="${ADMIN_USER}"
TERMUX_TMP="\${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
TERMUX_VK_ICD="/data/data/com.termux/files/usr/share/vulkan/icd.d"
VARS
        cat << 'BODY'
BINDS=""
X11_SOCK="${TERMUX_TMP}/.X11-unix"
[ -d "${X11_SOCK}" ]     && BINDS="${BINDS} --bind ${X11_SOCK}:/tmp/.X11-unix"
[ -d "/dev/dri" ]        && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ]   && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -d "${TERMUX_VK_ICD}" ] && BINDS="${BINDS} --bind ${TERMUX_VK_ICD}:/usr/share/vulkan/icd.d.termux"

proot-distro login "${PROOT_DISTRO}" ${BINDS} -- \
    env PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    bash -c "su - ${ADMIN_USER}"
BODY
    } > ~/shell-ubuntu.sh
    chmod +x ~/shell-ubuntu.sh
    echo "  [V] ~/shell-ubuntu.sh created"

    # --- stop-xfce.sh ---
    cat > ~/stop-xfce.sh << 'STOP'
#!/data/data/com.termux/files/usr/bin/bash
# stop-xfce.sh — Stop all sessions
echo "[*] Stopping..."
pkill -9 -f "com.termux.x11" 2>/dev/null; pkill -9 -f "termux-x11" 2>/dev/null
pkill -9 -f "pulseaudio"     2>/dev/null; pkill -9 -f "xfce4-session" 2>/dev/null
pkill -9 -f "xfwm4"          2>/dev/null; pkill -9 -f "dbus-daemon" 2>/dev/null
rm -f /tmp/.X0-lock 2>/dev/null
echo "[V] Done."
STOP
    chmod +x ~/stop-xfce.sh
    echo "  [V] ~/stop-xfce.sh created"
}

# --- Final message ---
show_done() {
    echo -e "\n${G}===================================================="
    echo "      INSTALLATION COMPLETE!"
    echo -e "====================================================${N}"
    echo "  User : ${ADMIN_USER} / ${ADMIN_PASS} (sudo NOPASSWD)"
    echo "  GPU  : ${GPU_MODE}"
    echo ""
    echo -e "${Y}USAGE INSTRUCTIONS:${N}"
    echo ""
    echo -e "${G}1. In FIRST Termux tab:${N}"
    echo "   bash ~/start-x11.sh"
    echo "   -> Wait for 'X11 & Audio Ready!'"
    echo "   -> Open Termux:X11 app on Android"
    echo ""
    echo -e "${G}2. In SECOND Termux tab:${N}"
    echo "   bash ~/start-xfce.sh"
    echo "   -> XFCE4 desktop will appear in Termux:X11 app"
    echo ""
    echo -e "${G}3. Ubuntu Shell (to install apps):${N}"
    echo "   bash ~/shell-ubuntu.sh"
    echo ""
    echo -e "${G}4. Stop everything:${N}"
    echo "   bash ~/stop-xfce.sh"
    echo ""
}

# --- Main ---
main() {
    [ ! -d "/data/data/com.termux" ] || [ ! -x "${TERMUX_PREFIX}/bin/bash" ] && \
        echo "Error: Please run this inside Termux!" && exit 1

    header
    detect_device
    confirm_start
    step1_termux_packages
    step2_install_ubuntu
    step3_ubuntu_base
    step4_ubuntu_xfce
    step5_create_admin
    step6_xfce_theme
    step7_gpu_env
    step8_launchers
    show_done
}

main
