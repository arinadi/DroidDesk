#!/data/data/com.termux/files/usr/bin/bash
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

# Build bind mounts  
BINDS=""
[ -d "/storage/emulated/0" ] && BINDS="$BINDS --bind /storage/emulated/0:/sdcard"

echo ">>> Starting XFCE Desktop..."
# shellcheck disable=SC2086
proot-distro login droiddesk --shared-tmp $BINDS -- env \
    DISPLAY=:0 \
    PULSE_SERVER=tcp:127.0.0.1:4713 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    NO_AT_BRIDGE=1 \
    bash -c '
        rm -f /tmp/dbus-* 2>/dev/null
        # compositing off handled by xfwm4.xml config
        dbus-launch --exit-with-session xfce4-session
    '
