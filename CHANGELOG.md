# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/); versioning is [SemVer](https://semver.org/).

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
