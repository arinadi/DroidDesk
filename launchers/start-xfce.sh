#!/data/data/com.termux/files/usr/bin/bash
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
X11_SOCK="${TERMUX_TMP}/.X11-unix"
PULSE_SOCK="${TERMUX_TMP}/pulse-socket"

# Build bind mounts
BINDS=""
[ -d "$X11_SOCK" ]   && BINDS="$BINDS --bind $X11_SOCK:/tmp/.X11-unix"
[ -e "$PULSE_SOCK" ] && BINDS="$BINDS --bind $PULSE_SOCK:/tmp/pulse-socket"
[ -d "/storage/emulated/0" ] && BINDS="$BINDS --bind /storage/emulated/0:/sdcard"

echo ">>> Starting XFCE Desktop..."
# shellcheck disable=SC2086,SC2016
proot-distro login ubuntu --shared-tmp $BINDS -- su - admin -c '

    # Export display and accessibility (suppress warnings)
    export DISPLAY=:0
    export NO_AT_BRIDGE=1

    # Set Audio to Host TCP
    export PULSE_SERVER=127.0.0.1

    # Fix XDG_RUNTIME_DIR permission issue
    export XDG_RUNTIME_DIR=/tmp/xdg-admin
    mkdir -p $XDG_RUNTIME_DIR
    chmod 700 $XDG_RUNTIME_DIR

    # Clean old dbus session
    rm -f /tmp/dbus-* 2>/dev/null

    # Start fresh session using dbus-launch (recommended for Termux-X11/proot)
    dbus-launch --exit-with-session startxfce4
'
