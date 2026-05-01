#!/data/data/com.termux/files/usr/bin/bash
# patch-ubuntudx.sh — Install essential Developer Experience tools
# Run from Termux host after proot-xfce-setup.sh
set -euo pipefail

DISTRO="ubuntu"
ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${DISTRO}"

if [ ! -d "$ROOTFS" ]; then
    echo "ERROR: Ubuntu proot not found. Run proot-xfce-setup.sh first."
    exit 1
fi

echo "==========================================="
echo " 🛠️  DroidDesk Developer Experience Patch"
echo "==========================================="
echo ""
echo " Packages: geany, git, gh, Node.js 24,"
echo "   python3-pip/venv, jq, htop, tree,"
echo "   ripgrep, nala, curl, wget, zip/unzip"
echo ""

# Write install script to rootfs tmp (avoids all quoting issues)
cat > "${ROOTFS}/tmp/_dx_install.sh" << 'DXEOF'
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo ">>> [1/4] Updating package lists..."
apt-get update -y -q

echo ">>> [2/4] Installing core dev tools..."
apt-get install -y -q --no-install-recommends \
    git curl wget ca-certificates gnupg \
    geany \
    python3-pip python3-venv \
    jq htop tree ripgrep \
    nala zip unzip

echo ">>> [3/4] Setting up GitHub CLI..."
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

echo ">>> [4/4] Setting up Node.js 24..."
if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
    apt-get install -y -q nodejs
else
    echo "  [-] node already installed ($(node --version)), skipping"
fi

# Cleanup apt cache
apt-get clean
rm -rf /var/lib/apt/lists/*

echo ""
echo "=== Installed Versions ==="
git --version 2>/dev/null          || echo "git: NOT FOUND"
gh --version 2>/dev/null | head -1 || echo "gh: NOT FOUND"
node --version 2>/dev/null         || echo "node: NOT FOUND"
npm --version 2>/dev/null          || echo "npm: NOT FOUND"
python3 --version 2>/dev/null      || echo "python3: NOT FOUND"
echo "geany $(geany --version 2>&1 | head -1)" 2>/dev/null || echo "geany: NOT FOUND"
echo "========================="
DXEOF

chmod +x "${ROOTFS}/tmp/_dx_install.sh"
proot-distro login "$DISTRO" -- bash /tmp/_dx_install.sh
rm -f "${ROOTFS}/tmp/_dx_install.sh"

echo ""
echo "==========================================="
echo " ✅ Developer Experience patch complete!"
echo "==========================================="
