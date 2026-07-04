<div align="center">
  <h1>📱 DroidDesk</h1>
  <p><strong>Your phone is a Linux workstation.</strong></p>
  <p>Full desktop environment with XFCE, Firefox, VS Code, and AI tools — running natively on Android.</p>
</div>

---

## ⚡ One Command Install

```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/bootstrap.sh | bash
```

That's it. Installs XFCE desktop, mobile-optimized theme, and all launchers. **Under 30 seconds.**

---

## 💡 Why DroidDesk?

### Your Phone, Your Desktop

Connect a monitor and it's a Linux PC. Unplug and your entire setup comes with you.

- 🖥️ **Full Desktop** — XFCE4 with mobile-optimized 64px panel, high DPI, dark theme
- 🌐 **Real Browsers** — Firefox ESR that doesn't sleep when screen is off
- 💻 **Real IDE** — VS Code, Geany, Neovim with native Node.js, Python, Git
- 🤖 **Local AI** — Ollama runs LLMs offline, 5+ tokens/sec
- 📱 **Android Integration** — Control battery, notifications, camera from Linux terminal

### Overcomes Android's Biggest Limitations

| Problem | DroidDesk Solution |
|---------|-------------------|
| Chrome sleeps background tabs | Full desktop browser in proot — stays alive |
| No glibc apps | Ubuntu proot with standard glibc |
| Can't run VS Code | Native Linux VS Code with extensions |
| Background processes killed | Termux:WakeLock keeps sessions alive |
| No developer tools | Full gcc, Node.js, Python, Docker |

---

## 🚀 Getting Started

### Requirements

- Android phone (ARM64)
- [Termux](https://f-droid.org/en/packages/com.termux/) (from F-Droid, NOT Play Store)
- [Termux:X11](https://github.com/termux/termux-x11/releases/tag/nightly) app
- [Termux:API](https://f-droid.org/en/packages/com.termux.api/) app (optional)

### Install

```bash
curl -sL https://raw.githubusercontent.com/arinadi/DroidDesk/main/bootstrap.sh | bash
```

### Start

```bash
bash ~/start-x11.sh    # Start X11 server + audio
# Open Termux:X11 app on your phone
bash ~/start-xfce.sh   # Start desktop
```

### Stop

```bash
bash ~/kill-all.sh     # Stop everything
```

---

## 📦 Install Software

After setup, add software with the patch installer:

```bash
# Interactive (choose what to install)
bash ~/.droiddesk/scripts/patch.sh

# Or install specific packages
bash ~/.droiddesk/scripts/patch.sh --firefox --code --nodejs

# See all available
bash ~/.droiddesk/scripts/patch.sh --list
```

### Available Packages

| Category | Packages |
|----------|----------|
| 🌐 Browser | Firefox ESR, Chromium |
| 💻 IDE | VS Code, Geany, Neovim |
| 🟢 Dev | Node.js 24, Python 3, Git, GitHub CLI, Build Essential |
| 🤖 AI | Ollama (local LLM) |
| 🖥️ System | htop, tmux, Zsh, Nala, Docker |
| 🔧 CLI | jq, tree, ripgrep, SQLite, curl, wget |
| 🎨 GUI | Viewnior, Xarchiver, Galculator |

---

## 🔄 Update

```bash
bash ~/update.sh
```

Or re-run install — it detects existing installation and offers to update.

---

## 🏗️ How It Works

```
┌─────────────────────────────────────┐
│  USER LAYER (mutable)               │  ← Your packages, configs, data
│  Firefox, VS Code, custom themes    │     Preserved across updates
├─────────────────────────────────────┤
│  IMAGE LAYER (immutable)            │  ← Pre-built from Dockerfile
│  Ubuntu 24.04 + XFCE + base tools   │     ghcr.io/arinadi/droiddesk
└─────────────────────────────────────┘
```

- **Install:** Pull pre-built image from GHCR (~30 seconds)
- **Update scripts:** Download new launchers from GitHub
- **Update packages:** `apt-get upgrade` inside proot
- **Major upgrade:** Auto backup/restore preserves your data

---

## 📱 Commands

| Command | Action |
|---------|--------|
| `bash ~/start-x11.sh` | Start X11 + PulseAudio |
| `bash ~/start-xfce.sh` | Start XFCE desktop |
| `bash ~/kill-all.sh` | Stop everything |
| `bash ~/kill-proot.sh` | Stop desktop only |
| `bash ~/kill-x11.sh` | Stop X11/audio only |
| `bash ~/update.sh` | Update DroidDesk |
| `bash ~/.droiddesk/scripts/patch.sh` | Install software |

---

## 🛑 Android 12+ Fix

If Termux crashes with `signal 9`:

- **Android 14+:** Developer Options → Disable child process restrictions
- **Android 12-13:** Run via ADB:
  ```bash
  adb shell settings put global settings_enable_monitor_phantom_procs false
  ```

---

## 📂 Project Structure

```
DroidDesk/
├── bootstrap.sh          ← curl target (entry point)
├── scripts/              ← setup + patch scripts
├── launchers/            ← desktop shortcuts
├── image/                ← Dockerfile + configs
├── docs/                 ← documentation
└── archive/              ← old files (git history)
```

---

## 📜 License

GPLv3
