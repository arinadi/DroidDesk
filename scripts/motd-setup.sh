#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Setting up MOTD..."

cat > /data/data/com.termux/files/usr/etc/motd << 'MOTDEOF'

==========================================
 📱 arinanoX Proot XFCE
==========================================

 Start:
    bash ~/start.sh  (widget: 1-start)

 Stop/Update:
    bash ~/stop.sh   (widget: 0-stop)
    bash ~/update.sh (widget: 2-update)

 User: admin / Pass: admin
==========================================
MOTDEOF

echo ">>> MOTD updated."
