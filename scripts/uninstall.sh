#!/bin/bash
# Remove the CUPS queue created by install.sh.
set -euo pipefail

QUEUE="${1:-Kyocera_FS_1370DN}"

if ! lpstat -p "$QUEUE" >/dev/null 2>&1; then
  echo "Queue '$QUEUE' does not exist; nothing to do."
  exit 0
fi

lpadmin -x "$QUEUE"
echo "Removed queue '$QUEUE'."
