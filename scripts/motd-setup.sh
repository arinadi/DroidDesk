#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ">>> Setting up MOTD..."

cat > /data/data/com.termux/files/usr/etc/motd << 'MOTDEOF'

==========================================
 📱 DroidDesk Proot XFCE
==========================================

 Start:
   1. bash ~/start-x11.sh
   2. Open Termux:X11 app
   3. bash ~/start-xfce.sh  (in new tab)

 Stop/Update:
    bash ~/kill-all.sh         (stop ALL)
    bash ~/kill-proot.sh       (stop XFCE only)
    bash ~/kill-x11.sh         (stop X11/Audio only)
    bash ~/update.sh           (update DroidDesk)

 User: admin / Pass: admin
==========================================
MOTDEOF

echo ">>> MOTD updated."
