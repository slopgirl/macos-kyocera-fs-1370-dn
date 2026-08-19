#!/usr/bin/env python3
"""Build ppd/Kyocera_FS-1370DN-macOS.ppd from the pristine upstream PPD.

The upstream PPD (from Kyocera's Linux driver package) assumes Kyocera's
kyofilter CUPS filter, which does not exist on macOS. Without it, several
option "codes" that kyofilter was supposed to consume get injected verbatim
into the job stream and corrupt it:

  - *JobDate emits a bare `timestamp=on` line into the PJL header
    (not valid PJL -> can knock the printer out of PJL parsing).
  - Placeholder code "0" (InputSlot Auto, CIE, Option8/18, ...) pushes
    stack litter into the PostScript setup section.
  - Margin adjustment emits `/Madj False def` -- `False` is not a
    PostScript token (booleans are lowercase).
  - The watermark group only defines variables kyofilter's PS template
    would read; useless (and risky) without the filter.

This script therefore:
  1. drops the *cupsFilter/*cupsPreFilter lines referencing kyofilter
     (KPDL3 is PostScript-compatible; macOS's PDF->PS chain drives it),
  2. drops embedded translations (*cupsLanguages + *de./*es./*fr./*it./*pt.
     lines; they trip a cupstestppd conformance bug),
  3. removes the StorageOptions, Adjustment and KmWatermark UI groups
     (kyofilter-only functionality) and any UIConstraints referencing
     their options,
  4. rewrites remaining placeholder feature code "0" to "" so nothing
     is injected for those choices.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "ppd" / "upstream" / "Kyocera_FS-1370DN.ppd.orig"
DST = ROOT / "ppd" / "Kyocera_FS-1370DN-macOS.ppd"

# UI groups implemented by kyofilter, not by the printer's interpreter.
DROP_GROUPS = {"StorageOptions", "Adjustment", "KmWatermark"}

# Options defined inside the dropped groups (for UIConstraints cleanup).
DROP_OPTIONS = {
    "Email", "JobName", "JobDate",            # StorageOptions
    "Madj", "Malt", "Mact",                   # Adjustment
    "Wren", "Wtxt", "Wfnt", "Wclr", "Wtyp",   # KmWatermark
    "Wang", "Wsze", "Wtrans", "Wflg", "Wpos",
    "Wadj", "Wfp", "KCSuperWatermark",
}

# Choice lines whose code is the kyofilter placeholder "0".
PLACEHOLDER_RE = re.compile(
    r'^(\*(?:Option8|Option18|CIE|InputSlot|MediaType|KCSuperWatermark|'
    r'LeadingEdge|\?Input)[^:]*): "0"'
)

LOCALE_RE = re.compile(r"^\*(?:de|es|fr|it|pt)\.")
CONSTRAINT_RE = re.compile(r"^\*(?:Non)?UIConstraints:")


def main() -> int:
    out = []
    group = None  # name of the group we are currently inside
    dropped_groups = dropped_lines = 0

    for line in SRC.read_text(encoding="latin-1").splitlines(keepends=True):
        m = re.match(r"^\*OpenGroup:\s*([A-Za-z0-9]+)", line)
        if m:
            group = m.group(1)
            if group in DROP_GROUPS:
                dropped_groups += 1
                continue
        if group in DROP_GROUPS:
            dropped_lines += 1
            if re.match(r"^\*CloseGroup:\s*" + re.escape(group), line):
                group = None
            continue
        if re.match(r"^\*CloseGroup:", line):
            group = None

        if "kyofilter" in line and line.startswith(("*cupsFilter", "*cupsPreFilter")):
            continue
        if line.startswith("*cupsLanguages:") or LOCALE_RE.match(line):
            continue
        if CONSTRAINT_RE.match(line) and any(
            re.search(r"\*" + opt + r"\b", line) for opt in DROP_OPTIONS
        ):
            continue

        m = PLACEHOLDER_RE.match(line)
        if m:
            line = m.group(1) + ': ""' + line[m.end():]

        out.append(line)

    DST.write_text("".join(out), encoding="latin-1")
    print(
        f"Wrote {DST.name}: {len(out)} lines "
        f"(removed {dropped_groups} groups / {dropped_lines} group lines)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
