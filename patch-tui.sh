#!/data/data/com.termux/files/usr/bin/bash
# patch-tui.sh — Interactive Package Installer for DroidDesk
# Run from Termux host. Uses dialog for checkbox TUI.
set -euo pipefail

DISTRO="ubuntu"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"

if [ ! -d "$ROOTFS" ]; then
    echo "ERROR: Ubuntu proot not found. Run proot-xfce-setup.sh first."
    exit 1
fi

# Ensure dialog is available on Termux host
command -v dialog &>/dev/null || { echo "[*] Installing dialog..."; pkg install -y dialog; }

# Temp file for dialog output
TMPFILE=$(mktemp "${PREFIX}/tmp/droiddesk_tui.XXXXXX")
trap "rm -f '$TMPFILE'" EXIT

# =============================================
#  Package Checklist
# =============================================
dialog --title " 📦 DroidDesk Package Installer " \
    --checklist "\n Select packages to install into Ubuntu proot.\n Use SPACE to toggle, ENTER to confirm.\n" \
    0 0 0 \
    "geany"           "📝 Lightweight IDE"          ON  \
    "git"             "🔧 Git Version Control"      ON  \
    "gh"              "🐙 GitHub CLI"               ON  \
    "nodejs"          "🟢 Node.js 24 (NodeSource)"  ON  \
    "python3-pip"     "🐍 Python Pip"               ON  \
    "python3-venv"    "🐍 Python Virtual Env"       ON  \
    "nala"            "📦 Modern APT Frontend"      ON  \
    "jq"              "📋 JSON Processor"           ON  \
    "htop"            "📊 Process Monitor"          ON  \
    "tree"            "🌳 Directory Tree View"      ON  \
    "ripgrep"         "🔍 Fast Grep (rg)"           ON  \
    "zip"             "📦 ZIP/UNZIP Tools"          ON  \
    "curl"            "🌐 HTTP Client"              ON  \
    "wget"            "⬇️  Download Manager"         ON  \
    "build-essential" "⚙️  GCC / Make / G++"         OFF \
    "cmake"           "⚙️  CMake Build System"       OFF \
    "tmux"            "🖥️  Terminal Multiplexer"     OFF \
    "vim"             "📝 Vim Editor"               OFF \
    "mousepad"        "📝 XFCE Notepad"             OFF \
    "firefox-esr"     "🌐 Firefox Browser"          OFF \
    "openssh-client"  "🔑 SSH Client"               OFF \
    "sqlite3"         "🗃️  SQLite CLI"               OFF \
    "fonts-firacode"  "🔤 Fira Code Font"           OFF \
    2>"$TMPFILE"

# Check if user cancelled
DIALOG_EXIT=$?
if [ $DIALOG_EXIT -ne 0 ]; then
    clear
    echo "Installation cancelled."
    exit 0
fi

SELECTIONS=$(cat "$TMPFILE")
if [ -z "$SELECTIONS" ]; then
    clear
    echo "No packages selected."
    exit 0
fi

# =============================================
#  Parse selections into categories
# =============================================
APT_PKGS=""
SETUP_GH=false
SETUP_NODE=false

for pkg in $SELECTIONS; do
    pkg=$(echo "$pkg" | tr -d '"')
    case "$pkg" in
        gh)      SETUP_GH=true ;;
        nodejs)  SETUP_NODE=true ;;
        zip)     APT_PKGS="$APT_PKGS zip unzip" ;;
        *)       APT_PKGS="$APT_PKGS $pkg" ;;
    esac
done

# Always ensure ca-certificates and gnupg for repo setup
if $SETUP_GH || $SETUP_NODE; then
    APT_PKGS="ca-certificates gnupg $APT_PKGS"
fi

# =============================================
#  Build install script
# =============================================
SCRIPT_PATH="${ROOTFS}/tmp/_tui_install.sh"

cat > "$SCRIPT_PATH" << 'HEADER'
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
echo ">>> Updating package lists..."
apt-get update -y -q
HEADER

# Apt packages
if [ -n "$APT_PKGS" ]; then
    # Deduplicate
    APT_PKGS=$(echo "$APT_PKGS" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    cat >> "$SCRIPT_PATH" << APTEOF
echo ">>> Installing apt packages..."
echo "    Packages: ${APT_PKGS}"
apt-get install -y -q --no-install-recommends ${APT_PKGS}
APTEOF
fi

# GitHub CLI (needs repo setup)
if $SETUP_GH; then
    cat >> "$SCRIPT_PATH" << 'GHEOF'
echo ">>> Setting up GitHub CLI..."
if ! command -v gh &>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    ARCH=$(dpkg --print-architecture)
    echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list
    apt-get update -y -q
    apt-get install -y -q gh
else
    echo "  [-] gh already installed, skipping"
fi
GHEOF
fi

# Node.js 24 (needs NodeSource)
if $SETUP_NODE; then
    cat >> "$SCRIPT_PATH" << 'NODEEOF'
echo ">>> Setting up Node.js 24..."
if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt-get install -y -q nodejs
else
    echo "  [-] node already installed ($(node --version)), skipping"
fi
NODEEOF
fi

# Cleanup and verification footer
cat >> "$SCRIPT_PATH" << 'FOOTER'
echo ""
echo ">>> Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*

echo ""
echo "=== Installation Summary ==="
command -v git    &>/dev/null && echo "  ✅ git      $(git --version 2>/dev/null)"
command -v gh     &>/dev/null && echo "  ✅ gh       $(gh --version 2>/dev/null | head -1)"
command -v node   &>/dev/null && echo "  ✅ node     $(node --version 2>/dev/null)"
command -v npm    &>/dev/null && echo "  ✅ npm      $(npm --version 2>/dev/null)"
command -v python3 &>/dev/null && echo "  ✅ python3  $(python3 --version 2>/dev/null)"
command -v geany  &>/dev/null && echo "  ✅ geany    installed"
command -v jq     &>/dev/null && echo "  ✅ jq       $(jq --version 2>/dev/null)"
command -v rg     &>/dev/null && echo "  ✅ ripgrep  $(rg --version 2>/dev/null | head -1)"
command -v htop   &>/dev/null && echo "  ✅ htop     installed"
command -v nala   &>/dev/null && echo "  ✅ nala     installed"
command -v tmux   &>/dev/null && echo "  ✅ tmux     installed"
command -v vim    &>/dev/null && echo "  ✅ vim      installed"
command -v cmake  &>/dev/null && echo "  ✅ cmake    $(cmake --version 2>/dev/null | head -1)"
command -v sqlite3 &>/dev/null && echo "  ✅ sqlite3  installed"
echo "============================="
FOOTER

# =============================================
#  Confirm & Execute
# =============================================
clear
echo "==========================================="
echo " 📦 DroidDesk Package Installer"
echo "==========================================="
echo ""
echo " Selected packages:"
for pkg in $SELECTIONS; do
    pkg=$(echo "$pkg" | tr -d '"')
    echo "   • $pkg"
done
echo ""
read -p " Proceed with installation? [Y/n] " -r CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    rm -f "$SCRIPT_PATH"
    echo "Installation cancelled."
    exit 0
fi

echo ""
chmod +x "$SCRIPT_PATH"
proot-distro login "$DISTRO" -- bash /tmp/_tui_install.sh
rm -f "$SCRIPT_PATH"

echo ""
echo "==========================================="
echo " ✅ Installation complete!"
echo "==========================================="
