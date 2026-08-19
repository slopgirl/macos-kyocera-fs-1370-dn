# NOTES (for Claude / future sessions)

## State of the machine (observed 2026-08-19)

- Two pre-existing queues, both on **Generic PostScript Printer** PPD (that's
  the problem this repo solves):
  - `Kyocera_FS_1370DN` → `usb://Kyocera/FS-1370DN?serial=Q660813081` (state offline-report at the time)
  - `Kyocera_FS_1370DN_2` → `usb://Kyocera/Kyocera%20FS-1370DN?serial=Q660813081`
  - Note the two different USB URI *product-string* variants for the same
    serial — the printer has enumerated both ways. install.sh prefers the
    live `lpinfo -v` value.
- There is also a `dnssd://...cups` share of the printer from host `eddie`
  (a remote CUPS server) — unrelated to the local USB setup.
- macOS 26.5.2 (Tahoe), CUPS with `cupstestppd` and `lpadmin` present.
  `shellcheck` and `just` availability: shellcheck NOT installed.

## PPD provenance chain

1. Old AUR package `kyocera-fs1370dn` (found via felixonmars/aur3-mirror)
   pointed to Kyocera's EU CDN — dead (403).
2. github.com/shoeper/kyocera-printer-install README carries an archive.org
   URL + SHA256 for Kyocera's official "Linux Driver Package.zip" (339 MB).
   Downloaded, **SHA256 verified**: `b2869b9d...d9b098b` ✓.
3. PPD extracted from `Debian/EU/kyodialog_amd64/kyodialog_7.0-0_amd64.deb`
   → `usr/share/kyocera7/ppd7/Kyocera_FS-1370DN.ppd` (3218 lines).
   Not available in foomatic-db (checked — no FS-1370DN there).

## Patches applied (orig → macOS PPD)

1. Dropped `*cupsPreFilter: kyofilter_pre_F` and `*cupsFilter: kyofilter_F`
   lines — Linux-only Python 2 filters (job accounting/watermark helpers).
   Without any cupsFilter line, CUPS treats the device as raw PostScript and
   uses the standard macOS PDF→PS chain. KPDL3 = PS3-compatible, so this works.
2. Dropped `*cupsLanguages` + all `*de./*es./*fr./*it./*pt.` lines:
   cupstestppd FAILs on missing "custom" param translations even though
   de/es/fr/it lines exist (upstream conformance bug; pt really is missing
   them). English-only PPD → clean PASS. Remaining WARNs are Adobe
   size-naming pedantry, harmless.

## Upstream PPD defaults (kept)

A4, DuplexNoTumble (duplex on, long edge), 601dpi (Kyocera's "600dpi + KIR"
notation), Gray. Good defaults for this user (Germany → A4).

## 0.2.0: PostScript error page diagnosis (2026-08-19, same day)

User's first print (after fixing a bad USB cable — printer wasn't even
enumerating on the bus; diagnose that with `ioreg -p IOUSB`, NOT
`system_profiler` which returns empty in the Claude sandbox) produced a
KPDL error page: `/unmatchedmark`, offending command `counttomark`.

Root cause found by regenerating the exact wire stream locally:
`cupsfilter -p <ppd> -m application/vnd.cups-postscript -o sides=... file`
— this is the go-to debugging technique here. The 0.1.0 PPD still carried
**kyofilter placeholder pseudo-code** that got injected verbatim:

- `*JobDate true` (default!) → bare `timestamp=on` line inside the PJL
  header. Not valid PJL; can knock the printer out of PJL parsing so
  `@PJL ENTER LANGUAGE=POSTSCRIPT` is never honored.
- Placeholder feature code `"0"` (InputSlot Auto, CIE, Option8/18,
  MediaType Auto, LeadingEdge, KCSuperWatermark None) → stack litter.
- `/Madj False def` — `False` is not a PostScript token (booleans are
  lowercase) → undefined error inside setup.
- Watermark group only defines variables for kyofilter's PS template.

Fix: `scripts/build_ppd.py` now generates the macOS PPD reproducibly and
removes the StorageOptions/Adjustment/KmWatermark groups + constraints,
neutralizes `"0"` codes. Verified the regenerated stream has a pristine
PJL header (hexdump: UEL → @PJL lines → `%!PS-Adobe-3.0`) and no junk.

Interesting: the PPD's `*KCVersion Default` code patches Apple's
`ct_AddStdCIDMap` from cg-pdf.ps — Kyocera explicitly engineered KPDL
against Apple's cgpdftops output, so the Apple prolog itself is fine.

If a PS error page ever appears again, next levers (untried):
`*LanguageLevel: "2"` in the PPD to make cgpdftops emit conservative
code, or PDF direct print (`*cupsFilter: "application/pdf 0 -"`, FS-1370DN
supports PDF direct — but PPD PS feature code like duplex stops working).

## Not yet verified on hardware

The queue install and an actual print were NOT run by Claude (user tests
manually, per their global CLAUDE.md). Verified so far: PPD passes
cupstestppd, scripts pass `bash -n`, install.sh --dry-run output correct.
If duplex or trays misbehave on real prints, first suspects: none known —
KPDL PPDs from this package are widely used on Linux CUPS.
