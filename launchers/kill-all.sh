#!/data/data/com.termux/files/usr/bin/bash
echo ">>> Stopping ALL DroidDesk services..."
echo ""
bash ~/.shortcuts/kill-proot.sh
echo ""
bash ~/.shortcuts/kill-x11.sh
echo ""
termux-wake-unlock 2>/dev/null
echo ">>> All DroidDesk services stopped."
