#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 1 — Systemd Anatomy${RESET}"; echo ""

pid1=$(ssh_vm "ps -p 1 -o comm= 2>/dev/null")
assert_contains "PID 1 is systemd" "$pid1" "systemd"

state=$(ssh_vm "systemctl is-system-running 2>/dev/null")
assert_contains "System is running" "$state" "running|degraded"

units=$(ssh_vm "systemctl list-units --type=service --state=running --no-pager 2>/dev/null")
assert_contains "Running services are listed" "$units" "ssh"

types=$(ssh_vm "systemctl -t help 2>/dev/null")
assert_contains "Unit types include service" "$types" "service"
assert_contains "Unit types include timer" "$types" "timer"

report_results "Exercise 1"
