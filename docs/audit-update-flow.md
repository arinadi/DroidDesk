═══════════════════════════════════════════
  AUDIT: update.sh + backup/restore flow
═══════════════════════════════════════════

## Current Flow

update.sh
  └─ curl bootstrap.sh | bash
       └─ proot-setup.sh
            ├─ backup: tar /home/admin (config, dotfiles, sessions, XFCE state)
            ├─ backup: dpkg --get-selections (ALL packages, no filter)
            ├─ remove old container
            ├─ install new image
            └─ restore: untar home + apt install all old packages

## 🔴 Risiko

1. CACHE_BUST masih ada di update.sh → 429 rate limit (sama kayak tadi!)
2. dpkg backup tidak filter image base vs user packages → restore bisa conflict
3. Home dir restore → stale XFCE sessions, ICEauthority corrupt, cache conflict
4. apt install with 2>/dev/null → silent failure, user gak tahu
5. Tar/untar di proot → permission issue, symlink rusak
6. Script corrupt (429) → semua gagal, user stranded
7. Complexity vs value: 30 detik fresh install vs 10+ failure modes

## 🟢 Rekomendasi

HAPUS auto-backup/restore. Ganti update.sh jadi simple:
  "Install fresh, pakai patch.sh untuk reinstall packages kamu."

Alasan:
- Install cuma 30 detik — faster than debugging broken restore
- User layer seharusnya cuma home dir + beberapa apt packages
- Package list bisa disimpan manual oleh user (dpkg -l > my-packages.txt)
- patch.sh sudah jadi installer yang teruji
- proot-backup.sh tetap ada sebagai tool OPSIONAL manual

## Files to change

update.sh        → simple: check version, offer reinstall
proot-setup.sh   → hapus auto-backup/restore
proot-backup.sh  → keep as manual tool (ubah header)
proot-restore.sh → keep as manual tool (ubah header)
