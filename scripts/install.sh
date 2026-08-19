#!/bin/bash
# Install the Kyocera FS-1370DN (USB) as a CUPS queue on macOS using the
# genuine Kyocera KPDL PPD (patched for macOS, see ppd/).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PPD="$SCRIPT_DIR/../ppd/Kyocera_FS-1370DN-macOS.ppd"

QUEUE="Kyocera_FS_1370DN"
DESCRIPTION="Kyocera FS-1370DN"
LOCATION="USB"
URI=""
DRY_RUN=0

usage() {
  cat <<EOF
Usage: install.sh [options]

Options:
  --queue NAME     CUPS queue name (default: $QUEUE)
  --uri URI        Device URI (default: auto-detect the USB printer)
  --location TEXT  Printer location label (default: $LOCATION)
  --dry-run        Show what would be done without changing anything
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --queue)    QUEUE="$2"; shift 2 ;;
    --uri)      URI="$2"; shift 2 ;;
    --location) LOCATION="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -f "$PPD" ]] || { echo "ERROR: PPD not found: $PPD" >&2; exit 1; }

# --- Find the printer's USB device URI -------------------------------------
# 1. Live USB detection (printer must be on and plugged in).
if [[ -z "$URI" ]]; then
  URI="$(lpinfo -v 2>/dev/null | awk '$1 == "direct" && $2 ~ /^usb:\/\/Kyocera/ && $2 ~ /1370/ {print $2; exit}')" || true
  [[ -n "$URI" ]] && echo "Detected USB printer: $URI"
fi

# 2. Fall back to the URI of an existing FS-1370DN queue (printer may be off).
if [[ -z "$URI" ]]; then
  URI="$(lpstat -v 2>/dev/null | grep -o 'usb://Kyocera[^ ]*1370[^ ]*' | head -1)" || true
  if [[ -n "$URI" ]]; then
    echo "Printer not detected live; reusing URI from an existing queue: $URI"
    echo "(If the printer was re-plugged since, run again with the printer switched on.)"
  fi
fi

if [[ -z "$URI" ]]; then
  cat >&2 <<'EOF'
ERROR: Could not find the FS-1370DN on USB.
  - Is the printer switched on and connected via USB?
  - Check with: lpinfo -v | grep usb
  - Or pass the URI explicitly: install.sh --uri 'usb://Kyocera/FS-1370DN?serial=...'
EOF
  exit 1
fi

# --- Install / update the queue ---------------------------------------------
echo "Installing queue '$QUEUE'"
echo "  URI: $URI"
echo "  PPD: $PPD"

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[dry-run] lpadmin -p $QUEUE -E -v $URI -P $PPD -D '$DESCRIPTION' -L '$LOCATION' \\"
  echo "            -o printer-is-shared=false -o printer-error-policy=retry-current-job"
  exit 0
fi

lpadmin -p "$QUEUE" -E -v "$URI" -P "$PPD" \
  -D "$DESCRIPTION" -L "$LOCATION" \
  -o printer-is-shared=false \
  -o printer-error-policy=retry-current-job

cupsenable "$QUEUE" 2>/dev/null || true
cupsaccept "$QUEUE" 2>/dev/null || true

# --- Verify -------------------------------------------------------------------
echo
echo "Queue state:"
lpstat -p "$QUEUE"
if lpoptions -p "$QUEUE" | grep -q "KPDL"; then
  echo "Driver: genuine Kyocera KPDL PPD active."
else
  echo "WARNING: queue exists but does not report the Kyocera KPDL PPD." >&2
fi

cat <<EOF

Done. Defaults: A4, duplex (long-edge), 600 dpi.
Test it with:  lp -d $QUEUE /usr/share/cups/data/testprint
EOF
