#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# patch.sh — Install optional packages into DroidDesk proot
# Interactive (no args) or CLI (with flags)

CONTAINER="droiddesk"

# === Available patches ===
declare -A PATCHES
PATCHES[firefox]="Firefox ESR|apt-get install -y firefox-esr"
PATCHES[code]="VS Code (code-server)|curl -fsSL https://code-server.dev/install.sh | sh"
PATCHES[node]="Node.js 24|curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && apt-get install -y nodejs"
PATCHES[python]="Python 3 + pip + venv|apt-get install -y python3-pip python3-venv"
PATCHES[ollama]="Ollama (local LLM)|curl -fsSL https://ollama.com/install.sh | sh"
PATCHES[docker]="Docker (rootless)|curl -fsSL https://get.docker.com | sh"
PATCHES[zsh]="Zsh + Oh My Zsh|apt-get install -y zsh && su - admin -c 'sh -c \"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" "" --unattended'"
PATCHES[neovim]="Neovim|apt-get install -y neovim"
PATCHES[htop]="htop + tmux|apt-get install -y htop tmux"
PATCHES[git]="Git + GitHub CLI|apt-get install -y git gh"

# === Parse args ===
SELECTED=()
INTERACTIVE=true

if [ $# -gt 0 ]; then
    INTERACTIVE=false
    for arg in "$@"; do
        case "$arg" in
            --firefox)  SELECTED+=("firefox") ;;
            --code)     SELECTED+=("code") ;;
            --node)     SELECTED+=("node") ;;
            --python)   SELECTED+=("python") ;;
            --ollama)   SELECTED+=("ollama") ;;
            --docker)   SELECTED+=("docker") ;;
            --zsh)      SELECTED+=("zsh") ;;
            --neovim)   SELECTED+=("neovim") ;;
            --htop)     SELECTED+=("htop") ;;
            --git)      SELECTED+=("git") ;;
            --all)      mapfile -t SELECTED < <(echo "${!PATCHES[@]}" | tr ' ' '\n') ;;
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
        printf "  %-12s %s" "[$key]" "$desc"
        read -rp "Install? [y/N] " ans
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
    read -rp "Proceed? [Y/n] " confirm
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
