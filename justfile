# Kyocera FS-1370DN macOS driver — useful recipes

# Show available recipes
default:
    @just --list

# Install (or update) the print queue with the Kyocera KPDL PPD
install *ARGS:
    scripts/install.sh {{ARGS}}

# Show what install would do, without changing anything
install-dry-run:
    scripts/install.sh --dry-run

# Remove the print queue
uninstall QUEUE="Kyocera_FS_1370DN":
    scripts/uninstall.sh {{QUEUE}}

# Show queue states, device URIs, and active driver
status:
    -lpstat -p
    -lpstat -v
    @echo "---"
    -lpoptions -p Kyocera_FS_1370DN | tr ' ' '\n' | grep -E "printer-make-and-model|device-uri|printer-state" || true

# Show USB printers currently visible to CUPS
detect:
    lpinfo -v | grep -i usb || echo "No USB printer detected (is it on and plugged in?)"

# Validate the patched PPD with cupstestppd
validate:
    cupstestppd ppd/Kyocera_FS-1370DN-macOS.ppd

# Print the CUPS test page (printer must be on)
test-page QUEUE="Kyocera_FS_1370DN":
    lp -d {{QUEUE}} /usr/share/cups/data/testprint

# Print a 2-page duplex test (both pages should land on one sheet)
test-duplex QUEUE="Kyocera_FS_1370DN":
    printf 'Duplex test page 1\n\x0cDuplex test page 2\n' | lp -d {{QUEUE}} -o sides=two-sided-long-edge

# Tail the CUPS error log
logs:
    tail -n 50 -f /var/log/cups/error_log
