#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
REPO="https://raw.githubusercontent.com/arinadi/arinanoX/main"

echo ">>> Updating arinanoX..."
curl -sL --retry 2 "${REPO}/bootstrap.sh" | bash
