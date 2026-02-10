#!/usr/bin/env bash
# systemd-lab install script

set -euo pipefail

echo ""
echo "  [systemd-lab] Installing..."
echo ""
echo "  This plugin demonstrates systemd service management inside"
echo "  a QEMU VM with sample services, timers, and journald logging."
echo ""
echo "  What you will learn:"
echo "    - How to manage systemd services (start, stop, enable, disable)"
echo "    - How to create custom systemd unit files"
echo "    - How to configure systemd timers as cron replacements"
echo "    - How to use journalctl for log analysis"
echo "    - How to set up service dependencies"
echo ""

# Create lab working directory
mkdir -p lab

# Check for required tools
echo "  Checking dependencies..."
local_ok=true
for cmd in qemu-system-x86_64 qemu-img genisoimage curl; do
    if command -v "$cmd" &>/dev/null; then
        echo "    [OK] $cmd"
    else
        echo "    [!!] $cmd — not found (install before running)"
        local_ok=false
    fi
done

if [[ "$local_ok" == true ]]; then
    echo ""
    echo "  All dependencies are available."
else
    echo ""
    echo "  Some dependencies are missing. Install them with:"
    echo "    sudo apt install qemu-kvm qemu-utils genisoimage curl"
fi

echo ""
echo "  [systemd-lab] Installation complete."
echo "  Run with: qlab run systemd-lab"
