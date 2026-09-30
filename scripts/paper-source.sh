#!/bin/bash
# Show or set the default paper source (InputSlot) of the FS-1370DN queue.
# `auto` sends no tray selection, so the printer's panel setting decides.
set -euo pipefail

QUEUE="Kyocera_FS_1370DN"

usage() {
  cat <<EOF
Usage: paper-source.sh [options] [SOURCE]

Without SOURCE, show the current default and the available choices.

SOURCE (friendly name or PPD name):
  auto       Auto    printer's own panel setting decides (recommended)
  cassette1  Tray1   Cassette 1
  cassette2  Tray2   Cassette 2 (optional PF-100 feeder)
  cassette3  Tray3   Cassette 3 (second optional PF-100 feeder)
  mp         MPTray  MP (multi-purpose) tray

Options:
  --queue NAME  CUPS queue name (default: $QUEUE)
  -h, --help    Show this help

A single job can override the default:
  lp -d $QUEUE -o InputSlot=MPTray file.pdf
EOF
}

SOURCE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --queue)   QUEUE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*)        echo "Unknown option: $1" >&2; usage; exit 2 ;;
    *)         SOURCE="$1"; shift ;;
  esac
done

show() {
  lpoptions -p "$QUEUE" -l | grep '^InputSlot/' \
    || { echo "ERROR: queue '$QUEUE' has no InputSlot option (installed?)" >&2; exit 1; }
}

if [[ -z "$SOURCE" ]]; then
  echo "Default paper source of '$QUEUE' (* = current):"
  show
  exit 0
fi

case "$(tr '[:upper:]' '[:lower:]' <<<"$SOURCE")" in
  auto)                      SLOT=Auto ;;
  # Kyocera's upstream keywords (internal, pf100a, ...) kept as aliases.
  cassette1|tray1|internal)  SLOT=Tray1 ;;
  cassette2|tray2|pf100a)    SLOT=Tray2 ;;
  cassette3|tray3|pf100b)    SLOT=Tray3 ;;
  mp|mptray|mf1)             SLOT=MPTray ;;
  *) echo "ERROR: unknown paper source '$SOURCE'" >&2; usage; exit 2 ;;
esac

lpadmin -p "$QUEUE" -o InputSlot-default="$SLOT"
echo "Default paper source of '$QUEUE' set to $SLOT:"
show
