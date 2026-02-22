#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 6 — Targets and Boot${RESET}"; echo ""

default=$(ssh_vm "systemctl get-default 2>/dev/null")
assert_contains "Default target is set" "$default" "multi-user.target|graphical.target"

targets=$(ssh_vm "systemctl list-units --type=target --no-pager 2>/dev/null")
assert_contains "Targets are listed" "$targets" "multi-user.target"

deps=$(ssh_vm "systemctl list-dependencies multi-user.target --no-pager 2>/dev/null | head -10")
assert_contains "Dependencies are listed" "$deps" "."

analyze=$(ssh_vm "systemd-analyze 2>/dev/null")
assert_contains "Boot analysis works" "$analyze" "Startup finished"

blame=$(ssh_vm "systemd-analyze blame --no-pager 2>/dev/null | head -5")
assert_contains "Blame analysis works" "$blame" "."

report_results "Exercise 6"
