#!/bin/bash
# arinanoX — APT Store (lightweight GUI package manager)
# Dependencies: yad, apt, sudo, curl, gpg
set -euo pipefail

TMP="/tmp/arinanox-store"
mkdir -p "$TMP"
command -v yad >/dev/null || { yad --error --text="yad not installed: apt install yad"; exit 1; }

# ═══ Helpers ═══
pkg_info() {
    local pkg="$1"
    local maint size desc installed
    maint=$(apt-cache show "$pkg" 2>/dev/null | grep "^Maintainer:" | head -1 | sed 's/^Maintainer: //')
    size=$(apt-cache show "$pkg" 2>/dev/null | grep "^Installed-Size:" | head -1 | awk '{printf "%.1f MB", $2/1024}')
    desc=$(apt-cache show "$pkg" 2>/dev/null | grep "^Description-en:" | head -1 | sed 's/^Description-en: //')
    installed=$(dpkg -s "$pkg" 2>/dev/null | grep "^Version:" | sed 's/^Version: //')
    echo "$maint|$size|$desc|$installed"
}

# ═══ Search ═══
do_search() {
    local query="$1"
    [ -z "$query" ] && { yad --info --text="Enter a search query." --width=250; return; }

    local results pkg desc yadargs
    results=$(apt-cache search "$query" 2>/dev/null | head -80)

    if [ -z "$results" ]; then
        yad --info --text="No results for '$query'\nTry 'Add Repository' to add more sources." --width=350
        return
    fi

    yadargs=""
    while IFS=' - ' read -r pkg desc; do
        pkg="${pkg%% *}"
        desc="${desc:0:70}"
        if dpkg -s "$pkg" &>/dev/null; then
            yadargs="$yadargs FALSE '$pkg' '$desc ✓'"
        else
            yadargs="$yadargs FALSE '$pkg' '$desc'"
        fi
    done <<< "$results"

    eval "set -- $yadargs"
    
    SELECTED=$(yad --title="Search: $query" \
        --width=650 --height=500 --center \
        --window-icon=system-software-install \
        --list --checklist --separator=" " \
        --column="✓" --column="Package" --column="Description" \
        --text="<b>Results for: $query</b>\n▸ ✓ = already installed" \
        --print-column=2 \
        --button="Install Selected":0 --button="Back":1 \
        "$@" 2>/dev/null)

    [ $? -ne 0 ] && return
    [ -z "$SELECTED" ] && { yad --info --text="Nothing selected." --width=250; return; }

    local info_list=""
    for p in $SELECTED; do
        IFS='|' read -r maint size desc installed <<< "$(pkg_info "$p")"
        info_list="$info_list\n<b>$p</b>  $size"
        [ -n "$maint" ] && info_list="$info_list\n   by: $maint"
        [ -n "$desc" ] && info_list="$info_list\n   $desc"
        info_list="$info_list\n"
    done

    yad --title="Confirm Install" --width=520 --height=250 \
        --window-icon=dialog-question \
        --text="<b>Install these packages?</b>$info_list" \
        --button="Install":0 --button="Cancel":1 2>/dev/null
    [ $? -ne 0 ] && return

    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y $SELECTED 2>&1 | \
        tail -15 | \
        yad --title="Installing..." --width=550 --height=350 \
            --text-info --button="OK" \
            --text="Installing: $SELECTED" 2>/dev/null
}

# ═══ Installed ═══
do_installed() {
    local count list
    count=$(dpkg -l 2>/dev/null | grep -c '^ii')
    list=$(dpkg -l 2>/dev/null | grep '^ii' | awk '{printf "%s|%s|%s\n", $2, $3, $5}' | sort | head -500 | tr '\n' ' ')

    yad --title="Installed Packages" --width=580 --height=520 --center \
        --list --column="Package" --column="Version" --column="Size" \
        --text="<b>$count packages installed</b>" \
        --button="OK" ${list} 2>/dev/null
}

# ═══ Upgrade ═══
do_upgrade() {
    local count list
    count=$(apt-get -s upgrade 2>/dev/null | grep "^Inst " | wc -l)
    
    if [ "$count" -eq 0 ]; then
        yad --info --text="✅ System is up to date." --width=250
        return
    fi

    list=$(apt-get -s upgrade 2>/dev/null | grep "^Inst " | awk '{printf "%s|%s\n", $2, $4}' | tr '\n' ' ')

    yad --title="Upgrade" --width=480 --height=380 --center \
        --text="<b>$count packages can be upgraded</b>" \
        --list --column="Package" --column="New Version" \
        --button="Upgrade All":0 --button="Cancel":1 \
        ${list} 2>/dev/null
    [ $? -ne 0 ] && return

    DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y 2>&1 | \
        tail -15 | \
        yad --title="Upgrade complete" --width=550 --height=350 \
            --text-info --button="OK" 2>/dev/null
}

# ═══ Sources list ═══
do_sources() {
    local sources
    sources=$(grep -v '^#\|^$' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null | sed 's/.*list://' | tail -50 | tr '\n' '|')

    yad --title="APT Sources" --width=650 --height=350 --center \
        --text="<b>Current repository sources</b>" \
        --text-info --button="OK" \
        --margins=10 \
        <<< "$(grep -v '^#\|^$' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null | sed 's/.*list://')" 2>/dev/null
}

# ═══ Add Repository ═══
do_add_repo() {
    # Show quick-add options or custom
    CHOICE=$(yad --title="Add Repository" \
        --width=420 --height=420 --center \
        --window-icon=package-add \
        --list --column="Option" --column="Description" \
        --text="<b>Add software source</b>" \
        --button="⚡ Quick Add":0 --button="✏️ Custom":2 --button="✕":1 \
        "📖 VS Code" "Microsoft Visual Studio Code (ARM64)" \
        "🦊 Firefox" "Mozilla Firefox latest (non-ESR)" \
        "🐳 Docker" "Docker Engine (ARM64)" \
        "☕ OpenJDK" "Temurin JDK (Eclipse Adoptium)" \
        "🔧 Custom" "Add any APT repository manually" 2>/dev/null)

    RET=$?
    [ $RET -ne 0 ] && return

    case "$RET" in
        0)
            OPT=$(echo "$CHOICE" | cut -d'|' -f1)
            case "$OPT" in
                "📖 VS Code")
                    REPO="deb [arch=arm64] https://packages.microsoft.com/repos/code stable main"
                    KEY_URL="https://packages.microsoft.com/keys/microsoft.asc"
                    KEY_NAME="microsoft"
                    ;;
                "🦊 Firefox")
                    REPO="deb [arch=arm64] http://packages.mozilla.org/apt mozilla main"
                    KEY_URL="https://packages.mozilla.org/apt/repo-signing-key.gpg"
                    KEY_NAME="mozilla"
                    ;;
                "🐳 Docker")
                    REPO="deb [arch=arm64] https://download.docker.com/linux/debian trixie stable"
                    KEY_URL="https://download.docker.com/linux/debian/gpg"
                    KEY_NAME="docker"
                    ;;
                "☕ OpenJDK")
                    REPO="deb [arch=arm64] https://packages.adoptium.net/artifactory/deb trixie main"
                    KEY_URL="https://packages.adoptium.net/artifactory/api/gpg/key/public"
                    KEY_NAME="adoptium"
                    ;;
                *)
                    return
                    ;;
            esac

            # Add key
            yad --title="Adding $KEY_NAME..." --text="Downloading signing key..." \
                --width=300 --progress --pulsate --auto-close --no-buttons &
            PID=$!
            
            if curl -fsSL "$KEY_URL" | sudo gpg --dearmor -o "/usr/share/keyrings/${KEY_NAME}.gpg" 2>/dev/null; then
                kill $PID 2>/dev/null
                
                REPO_LINE="deb [arch=arm64 signed-by=/usr/share/keyrings/${KEY_NAME}.gpg]"
                # Add the rest after the signed-by part
                REPO_LINE="$REPO_LINE ${REPO#deb \[arch=arm64\] }"
                echo "$REPO_LINE" | sudo tee "/etc/apt/sources.list.d/${KEY_NAME}.list" > /dev/null
                
                # Update cache
                yad --title="Updating..." --text="Updating package cache..." \
                    --width=300 --progress --pulsate --auto-close --no-buttons &
                PID=$!
                sudo apt-get update -qq 2>&1 | tail -1
                kill $PID 2>/dev/null
                
                yad --info --text="✅ Repository added\n\nSource: ${KEY_NAME}\nRun Search to find new packages." --width=350
            else
                kill $PID 2>/dev/null
                yad --error --text="❌ Failed to download key from:\n$KEY_URL" --width=350
            fi
            ;;
        2)
            # Custom — user enters repo info manually
            FORM=$(yad --title="Custom Repository" --width=480 --center \
                --form \
                --field="Repo Line": "deb [arch=arm64] " \
                --field="Key URL": "" \
                --field="Name": "" \
                --button="Add":0 --button="Cancel":1 2>/dev/null)
            [ $? -ne 0 ] && return

            REPO=$(echo "$FORM" | cut -d'|' -f1)
            KEY_URL=$(echo "$FORM" | cut -d'|' -f2)
            KEY_NAME=$(echo "$FORM" | cut -d'|' -f3 | tr ' ' '_')
            [ -z "$KEY_NAME" ] && KEY_NAME="custom-$(date +%s)"

            if [ -n "$KEY_URL" ]; then
                curl -fsSL "$KEY_URL" | sudo gpg --dearmor -o "/usr/share/keyrings/${KEY_NAME}.gpg" 2>/dev/null
                REPO_SIGNED="deb [arch=arm64 signed-by=/usr/share/keyrings/${KEY_NAME}.gpg] ${REPO#deb*\] }"
                echo "$REPO_SIGNED" | sudo tee "/etc/apt/sources.list.d/${KEY_NAME}.list" > /dev/null
            else
                echo "$REPO" | sudo tee "/etc/apt/sources.list.d/${KEY_NAME}.list" > /dev/null
            fi

            sudo apt-get update -qq 2>&1 | tail -1
            yad --info --text="✅ Custom repository added." --width=300
            ;;
    esac
}

# ═══ Main ═══
while true; do
    CHOICE=$(yad --title="arinanoX Store" \
        --width=380 --height=360 --center \
        --window-icon=system-software-install \
        --form \
        --field="":LBL "<b>APT Package Manager</b>" \
        --field="Search": "" \
        --button="🔍 Search":0 \
        --button="📦 Installed":2 \
        --button="➕ Add Repo":3 \
        --button="📋 Sources":5 \
        --button="⬆️ Upgrade":4 \
        --button="✕":1 2>/dev/null)

    RET=$?
    QUERY=$(echo "$CHOICE" | cut -d'|' -f2 | tr -d '\n')

    case $RET in
        0) do_search "$QUERY" ;;
        2) do_installed ;;
        3) do_add_repo ;;
        4) do_upgrade ;;
        5) do_sources ;;
        *) exit 0 ;;
    esac
done
