#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# patch.sh — Install optional software into DroidDesk proot
# Interactive (no args) or CLI (with flags)

CONTAINER="droiddesk"

declare -A PATCHES

# Browsers
PATCHES[chromium]="Chromium Browser|apt-get install -y chromium-browser"

# Development
PATCHES[code]="VS Code (code-server)|curl -fsSL https://code-server.dev/install.sh | sh"
PATCHES[geany]="Geany (Lightweight IDE)|apt-get install -y geany"
PATCHES[neovim]="Neovim|apt-get install -y neovim"

# AI
PATCHES[ollama]="Ollama (local LLM)|curl -fsSL https://ollama.com/install.sh | sh"

# System
PATCHES[zsh]="Zsh + Oh My Zsh|apt-get install -y zsh && su - admin -c 'sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended'"
PATCHES[nala]="Nala (Modern APT)|apt-get install -y nala"
PATCHES[docker]="Docker (rootless)|curl -fsSL https://get.docker.com | sh"

# CLI Tools (only ones NOT in image)
PATCHES[ripgrep]="Fast Grep (rg)|apt-get install -y ripgrep"

# GUI Apps
PATCHES[viewnior]="Image Viewer (Viewnior)|apt-get install -y viewnior"
PATCHES[xarchiver]="Archive Manager|apt-get install -y xarchiver"
PATCHES[galculator]="Calculator (Galculator)|apt-get install -y galculator"
PATCHES[github]="GitHub CLI|apt-get install -y gh"

# === Parse args ===
SELECTED=()
INTERACTIVE=true

if [ $# -gt 0 ]; then
    INTERACTIVE=false
    for arg in "$@"; do
        case "$arg" in
            --chromium)   SELECTED+=("chromium") ;;
            --code)       SELECTED+=("code") ;;
            --geany)      SELECTED+=("geany") ;;
            --neovim)     SELECTED+=("neovim") ;;
            --ollama)     SELECTED+=("ollama") ;;
            --zsh)        SELECTED+=("zsh") ;;
            --nala)       SELECTED+=("nala") ;;
            --docker)     SELECTED+=("docker") ;;
            --ripgrep)    SELECTED+=("ripgrep") ;;
            --viewnior)   SELECTED+=("viewnior") ;;
            --xarchiver)  SELECTED+=("xarchiver") ;;
            --galculator) SELECTED+=("galculator") ;;
            --github)     SELECTED+=("github") ;;
            --all)        mapfile -t SELECTED < <(echo "${!PATCHES[@]}" | tr ' ' '\n') ;;
            --list)
                echo "Available patches:"
                for key in $(echo "${!PATCHES[@]}" | tr ' ' '\n' | sort); do
                    desc="${PATCHES[$key]%%|*}"
                    echo "  --$(echo "$key" | tr '_' '-')  $desc"
                done
                exit 0
                ;;
            *) echo "Unknown: $arg (use --list)"; exit 1 ;;
        esac
    done
fi

# === Interactive mode ===
if $INTERACTIVE; then
    echo ""
    echo "╔═══════════════════════════════════╗"
    echo "║  📦 DroidDesk Patch Installer     ║"
    echo "╠═══════════════════════════════════╣"
    echo ""

    for key in $(echo "${!PATCHES[@]}" | tr ' ' '\n' | sort); do
        IFS='|' read -r desc cmd <<< "${PATCHES[$key]}"
        printf "  %-14s %s" "[$key]" "$desc"
        if [ -t 0 ]; then read -rp " Install? [y/N] " ans; else ans="y"; fi
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            SELECTED+=("$key")
        fi
    done

    echo ""
    if [ ${#SELECTED[@]} -eq 0 ]; then
        echo "Nothing selected. Exiting."
        exit 0
    fi

    echo "Will install: ${SELECTED[*]}"
    if [ -t 0 ]; then read -rp "Proceed? [Y/n] " confirm; else confirm="y"; fi
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# === Install ===
echo ""
echo ">>> Installing ${#SELECTED[@]} patches..."

for key in "${SELECTED[@]}"; do
    IFS='|' read -r desc cmd <<< "${PATCHES[$key]}"
    echo ""
    echo ">>> [$key] $desc"
    proot-distro login "$CONTAINER" -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        $cmd
    " || echo "  ⚠️  Failed: $key"
done

echo ""
echo ">>> Done! ${#SELECTED[@]} patches installed."
