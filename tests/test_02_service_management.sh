#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 2 — Service Management${RESET}"; echo ""

status=$(ssh_vm "systemctl is-active sample.service 2>/dev/null")
assert_contains "sample.service is active" "$status" "active"

assert "Stop sample.service" ssh_vm "sudo systemctl stop sample.service"
stopped=$(ssh_vm "systemctl is-active sample.service 2>/dev/null" || echo "inactive")
assert_contains "Service is inactive after stop" "$stopped" "inactive"

assert "Start sample.service" ssh_vm "sudo systemctl start sample.service"
started=$(ssh_vm "systemctl is-active sample.service 2>/dev/null")
assert_contains "Service is active after start" "$started" "active"

assert "Restart sample.service" ssh_vm "sudo systemctl restart sample.service"

cat_output=$(ssh_vm "systemctl cat sample.service 2>/dev/null")
assert_contains "Unit file is readable" "$cat_output" "Service|ExecStart"

# Restore
ssh_vm "sudo systemctl enable sample.service 2>/dev/null" || true

report_results "Exercise 2"
