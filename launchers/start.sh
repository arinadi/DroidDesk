#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Start (unified launcher)
#  PulseAudio → X11 → virgl (auto) → XFCE desktop
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
ANGLE_DIR="/data/data/com.termux/files/usr/opt/angle-android"

# ── PulseAudio ──────────────────────────────────────────────
echo ">>> [1/4] PulseAudio..."
pulseaudio --start --exit-idle-time=-1
pactl load-module module-aaudio-sink 2>/dev/null || pactl load-module module-sles-sink 2>/dev/null || true
pactl load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 port=4713 2>/dev/null || true
echo "  ✓ PulseAudio ready"

# ── Termux:API Bridge ───────────────────────────────────────
echo ">>> [2/4] Termux:API Bridge..."
termux-wake-lock
pkill -f run-api-bridge.sh 2>/dev/null || true
bash ~/run-api-bridge.sh > /dev/null 2>&1 &
echo "  ✓ API bridge started"

# ── Termux:X11 ──────────────────────────────────────────────
echo ">>> [3/4] X11 Server..."
export XDG_RUNTIME_DIR="$TERMUX_TMP"
termux-x11 :0 -ac &
sleep 2
am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true
echo "  ✓ X11 running"

# ── virgl GPU (auto-detect best path) ───────────────────────
echo ">>> [4/4] Desktop..."
VIRGL_MODE="cpu"

# 1: android (native GLES) — best for most devices
if command -v virgl_test_server_android &>/dev/null; then
    echo "  ✓ android GPU — starting server..."
    virgl_test_server_android &>/dev/null &
    sleep 1
    VIRGL_MODE="android"

# 2: angle + vulkan-null (faster passthrough)
elif command -v virgl_test_server &>/dev/null && [ -d "${ANGLE_DIR}/vulkan-null" ]; then
    echo "  ✓ ANGLE+vulkan-null — starting server..."
    LD_LIBRARY_PATH="${ANGLE_DIR}/vulkan-null" virgl_test_server --use-egl-surfaceless --use-gles &>/dev/null &
    sleep 1
    VIRGL_MODE="angle-vulkan-null"

# 3: angle + vulkan (full translation)
elif command -v virgl_test_server &>/dev/null && [ -d "${ANGLE_DIR}/vulkan" ]; then
    echo "  ✓ ANGLE+vulkan — starting server..."
    LD_LIBRARY_PATH="${ANGLE_DIR}/vulkan" virgl_test_server --use-egl-surfaceless --use-gles &>/dev/null &
    sleep 1
    VIRGL_MODE="angle-vulkan"

else
    echo "  • no GPU server available (CPU rendering)"
fi

# ── XFCE Desktop ────────────────────────────────────────────
if [ "$VIRGL_MODE" != "cpu" ]; then
    echo "  ✓ Launching XFCE with GPU (${VIRGL_MODE})..."
    proot-distro login arinanox --shared-tmp -- su - admin -c "
        export DISPLAY=:0
        export PULSE_SERVER=tcp:127.0.0.1:4713
        export NO_AT_BRIDGE=1
        export GALLIUM_DRIVER=virpipe
        export MESA_GL_VERSION_OVERRIDE=4.1COMPAT
        export MESA_GLES_VERSION_OVERRIDE=3.1
        export MESA_NO_ERROR=1
        export MESA_BACK_BUFFER=pixmap
        rm -f /tmp/dbus-* 2>/dev/null
        dbus-launch --exit-with-session xfce4-session
    "
else
    echo "  ✓ Launching XFCE (CPU rendering)..."
    proot-distro login arinanox --shared-tmp -- su - admin -c "
        export DISPLAY=:0
        export PULSE_SERVER=tcp:127.0.0.1:4713
        export NO_AT_BRIDGE=1
        export LIBGL_ALWAYS_SOFTWARE=1
        rm -f /tmp/dbus-* 2>/dev/null
        dbus-launch --exit-with-session xfce4-session
    "
fi

echo ">>> arinanoX desktop ended."
