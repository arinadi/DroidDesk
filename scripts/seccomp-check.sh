#!/data/data/com.termux/files/usr/bin/bash
# ═══════════════════════════════════════════════════════════════
# arinanoX — Seccomp Compatibility Check
# Detects Android 15+ seccomp-bpf filtering that breaks proot
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

echo ">>> seccomp-check: arinanoX compatibility probe"

# ── Android SDK detection ───────────────────────────────────
SDK=$(getprop ro.build.version.sdk 2>/dev/null || echo "0")
RELEASE=$(getprop ro.build.version.release 2>/dev/null || echo "unknown")
DEVICE=$(getprop ro.product.model 2>/dev/null || echo "unknown")

echo "  Android SDK: ${SDK} (${RELEASE})"
echo "  Device:      ${DEVICE}"
echo "  Arch:        $(uname -m)"

SEVERITY="safe"
MITIGATION=""
PROBE_RESULT="unknown"

# ── Probe: try a glibc binary through proot ─────────────────
if command -v proot-distro &>/dev/null; then
    if proot-distro login arinanox -- bash -c 'echo ok' &>/dev/null; then
        PROBE_RESULT="pass"
        echo "  Probe:       ✓ proot exec works"
    else
        PROBE_RESULT="fail"
        echo "  Probe:       ✗ proot exec FAILED (SIGSYS?)"
        SEVERITY="critical"
    fi
else
    PROBE_RESULT="no-proot"
    echo "  Probe:       - no proot container (fresh install?)"
fi

# ── Seccomp analysis ────────────────────────────────────────
# Android 34+ (v14) introduced stricter seccomp
if [ "$SDK" -ge 34 ]; then
    if [ "$PROBE_RESULT" = "fail" ]; then
        SEVERITY="critical"
        MITIGATION="PROOT_NO_SECCOMP=1"
        echo ""
        echo "  ╔══════════════════════════════════════════════════════╗"
        echo "  ║  ⚠ CRITICAL: seccomp blocking proot               ║"
        echo "  ║  Android ${RELEASE} (SDK ${SDK})                          ║"
        echo "  ╠══════════════════════════════════════════════════════╣"
        echo "  ║  Mitigation: set PROOT_NO_SECCOMP=1               ║"
        echo "  ║  Run: bash ~/.arinanox/scripts/seccomp-fix.sh     ║"
        echo "  ╚══════════════════════════════════════════════════════╝"
    else
        SEVERITY="patched"
        echo "  Status:      ✓ Android ${SDK} but proot working (OEM patch?)"
    fi
else
    echo "  Status:      ✓ SDK < 34, no seccomp risk"
fi

echo ""
echo "  Summary:     severity=${SEVERITY}  probe=${PROBE_RESULT}"

# Return code for scripting
[ "$SEVERITY" = "critical" ] && exit 1 || exit 0
