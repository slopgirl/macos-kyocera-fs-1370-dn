# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/); versioning is [SemVer](https://semver.org/).

## [0.3.0] - 2026-09-30

### Changed
- The queue's default paper source is `Auto` again: jobs carry no tray
  selection, so the paper source set on the printer's panel is honored.
  Reverts the 0.2.1 Cassette 1 pin, which sent `setpapertray 0` with every
  job and made the panel setting unusable. Re-running the install resets a
  previously pinned tray.

### Fixed
- The macOS print dialog's Paper Feed pane was empty: Kyocera's InputSlot
  keywords (`Internal`, `PF100A`, `PF100B`, `MF1`) became non-standard IPP
  media-source keywords the dialog doesn't list. The generated PPD now uses
  `Tray1`, `Tray2`, `Tray3`, `MPTray` (→ `tray-1..3`, `by-pass-tray`);
  display names and PostScript code are unchanged.

### Added
- `install.sh --input-slot Auto|Tray1|Tray2|Tray3|MPTray` to pin a
  default paper source deliberately.
- `just paper-source [SOURCE]` (`scripts/paper-source.sh`): show or change
  the queue's default paper source without reinstalling; accepts friendly
  names (`auto`, `cassette1`–`cassette3`, `mp`) or PPD names.

## [0.2.1] - 2026-08-19

### Fixed
- Jobs drew paper from an unexpected source: the `Auto` input slot emits no
  source selection, letting Kyocera firmware prefer the MP tray whenever it
  holds paper. The queue now defaults to Cassette 1
  (`-o InputSlot-default=Internal` in install.sh); per-job override in the
  print dialog still works.

## [0.2.0] - 2026-08-19

### Fixed
- Printer emitted a PostScript error page (`/unmatchedmark` in
  `counttomark`) on every job: leftover kyofilter placeholder pseudo-code
  in the PPD corrupted the job stream. The `*JobDate` option injected a
  bare `timestamp=on` line into the PJL header (invalid PJL), placeholder
  feature code `"0"` pushed stack litter, and `/Madj False def` is not
  valid PostScript (`False` vs `false`). All kyofilter-only UI groups
  (job settings, margin adjustment, watermark) are now removed and
  placeholder codes neutralized.

### Added
- `scripts/build_ppd.py`: reproducible generation of the macOS PPD from
  the pristine upstream PPD (replaces the ad-hoc sed patching);
  `just build-ppd` recipe.

## [0.1.0] - 2026-08-19

### Added
- Genuine Kyocera FS-1370DN KPDL PPD, extracted from Kyocera's official Linux
  driver package (kyodialog 7.0, checksum-verified via archive.org), with a
  pristine copy under `ppd/upstream/`.
- macOS-patched PPD (`ppd/Kyocera_FS-1370DN-macOS.ppd`): Linux-only
  `kyofilter` filter references removed, broken embedded translations
  stripped. Passes `cupstestppd`.
- `scripts/install.sh`: idempotent queue setup with USB URI auto-detection
  (live via `lpinfo -v`, falling back to an existing queue's URI),
  `--dry-run`/`--queue`/`--uri`/`--location` options.
- `scripts/uninstall.sh`: queue removal.
- `justfile` recipes: install, uninstall, status, detect, validate,
  test-page, test-duplex, logs.
- README with provenance, usage, and troubleshooting; NOTES with session
  findings.
