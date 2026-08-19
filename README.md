# Kyocera FS-1370DN on macOS (USB)

Scripts to install a **working macOS driver** for the Kyocera FS-1370DN USB
laser printer, using the **genuine Kyocera KPDL PPD** instead of the Generic
PostScript fallback.

## Why

Kyocera never shipped a driver for modern macOS, so the printer typically ends
up on the "Generic PostScript Printer" PPD — which loses duplex printing,
correct trays/media handling, EcoPrint, and proper margins.

The FS-1370DN is a true PostScript printer (KPDL3 = PostScript 3 compatible),
so no driver *binary* is needed at all — only the correct PPD. This repo ships
Kyocera's official PPD (from their Linux driver package) with two small
patches so it works on macOS:

- Removed `*cupsFilter`/`*cupsPreFilter` lines referencing Kyocera's
  Linux-only Python 2 filters (`kyofilter_F`). macOS's standard PDF→PostScript
  chain drives the printer directly.
- Removed the embedded de/es/fr/it/pt PPD translations (they trip a
  `cupstestppd` conformance bug upstream). macOS localizes all standard print
  dialog options itself; only Kyocera-specific feature names appear in English.

The patched PPD passes `cupstestppd` (`just validate`).

## Install

```sh
just install          # or: scripts/install.sh
```

The script auto-detects the printer's USB URI (`usb://Kyocera/...1370...`),
falling back to the URI of an existing queue if the printer is currently off.
It then creates/updates the CUPS queue `Kyocera_FS_1370DN` with the patched
PPD and enables it. Re-running is safe (idempotent).

Defaults after install: **A4, duplex (long-edge), 600 dpi, mono.**

Options: `--queue NAME`, `--uri URI`, `--location TEXT`, `--dry-run`.

## Test

```sh
just test-page        # CUPS test page
just test-duplex      # 2 pages that should land on one sheet
```

## Other recipes

```sh
just status           # queue states, URIs, active driver
just detect           # USB printers CUPS can see right now
just validate         # cupstestppd on the patched PPD
just uninstall        # remove the queue
just logs             # tail CUPS error log
```

## Troubleshooting

- **Queue says `offline-report` / jobs stuck**: printer off, asleep, or the
  USB URI changed. Power-cycle the printer, re-plug USB, then `just install`
  again (it re-detects the URI).
- **Two URI variants exist** (`usb://Kyocera/FS-1370DN?serial=...` and
  `usb://Kyocera/Kyocera%20FS-1370DN?serial=...`) — the printer has announced
  itself both ways over time. The installer prefers whatever `lpinfo -v`
  reports *live*, which is the one that will actually connect.
- **Leftover duplicate queues** (e.g. `Kyocera_FS_1370DN_2`): remove with
  `just uninstall Kyocera_FS_1370DN_2`.
- **Debugging**: `cupsctl --debug-logging`, then `just logs`
  (turn off again with `cupsctl --no-debug-logging`).

## PPD provenance

- Source: Kyocera "Linux Driver Package.zip" (kyodialog 7.0, EU),
  via archive.org ([link](http://web.archive.org/web/20200327053727if_/https://downloads.kyoceradocumentsolutions.com.au/drivers/Drivers/Linux%20Driver%20Package.zip)),
  SHA256 `b2869b9d00bd420291b2592da32e5787f8395e0f5f9961317b9518781d9b098b`.
- Extracted from `Debian/EU/kyodialog_amd64/kyodialog_7.0-0_amd64.deb`,
  path `usr/share/kyocera7/ppd7/Kyocera_FS-1370DN.ppd`.
- Pristine copy: `ppd/upstream/Kyocera_FS-1370DN.ppd.orig`;
  patched: `ppd/Kyocera_FS-1370DN-macOS.ppd`.
- The PPD is © Kyocera, redistributed unmodified apart from the patches
  described above; kept here for personal use.
