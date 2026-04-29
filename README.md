# DroidDesk Proot XFCE

A focused guide for `proot-xfce-setup.sh`.

This script installs XFCE inside a selected proot distro and creates separate start scripts for Termux:X11 and the proot session.

The original Termux-centered guide is preserved in `readme-termux.md`.

## What this script does

- Installs Termux-required packages: `x11-repo`, `termux-x11-nightly`, `proot`, `proot-distro`
- Installs one of these proot distros:
  - Ubuntu 22.04 LTS
  - Debian 12
  - Kali Linux
- Installs XFCE and basic GUI tooling inside the selected distro
- Creates the following launcher scripts:
  - `~/start-x11.sh` — start Termux:X11 and PulseAudio
  - `~/start-xfce.sh` — start XFCE session inside the proot distro
  - `~/kill-proot.sh` — kill all XFCE/proot processes and clean temp files
  - `~/kill-x11.sh` — kill X11 and PulseAudio, clean sockets

## Requirements

- Android phone (ARM64)
- Termux installed from F-Droid
- Termux:X11 Android app installed from the nightly release

## Install

You can install the script directly from this repository or run it from a local clone.

### Option 1: Download and run directly from GitHub

```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/proot-xfce-setup.sh -o ~/proot-xfce-setup.sh
chmod +x ~/proot-xfce-setup.sh
bash ~/proot-xfce-setup.sh
```

### Option 2: Run from a local repository clone

```bash
cd /workspaces/DroidDesk
bash proot-xfce-setup.sh
```

Choose the distro when prompted.

## Usage

### 1. Start the X11 server

```bash
bash ~/start-x11.sh
```

This starts Termux:X11 on display `:1`.

### 2. Start XFCE inside the proot distro

```bash
bash ~/start-xfce.sh
```

This launches the XFCE session in the selected proot container using `DISPLAY=:0`.

### 3. Stop XFCE / proot

```bash
bash ~/kill-proot.sh
```

Kills all XFCE and proot processes, cleans temp files inside rootfs (preserves config).

### 4. Stop X11 / audio

```bash
bash ~/kill-x11.sh
```

Kills Termux:X11 and PulseAudio, removes socket and lock files.

## Recommended flow

**Start:**
1. `bash ~/start-x11.sh`
2. Open Termux:X11 app
3. `bash ~/start-xfce.sh` (in new Termux tab)

**Stop:**
1. `bash ~/kill-proot.sh`
2. `bash ~/kill-x11.sh`

## Notes

- `~/start-xfce.sh` requires `~/start-x11.sh` to be running first.
- Start scripts only start — they do not kill previous sessions. Run the kill scripts first if you need a clean restart.
- The container session uses `dbus-run-session startxfce4`.
- If the display is unstable, you may later add Termux:X11 flags such as `-legacy-drawing` or `-force-bgra`.

## Original Termux guide

See `readme-termux.md` for the full original Termux/XFCE documentation.

## License

Released under the GPLv3 license.
