#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 4 — Journald and Logging${RESET}"; echo ""

logs=$(ssh_vm "journalctl --no-pager -n 5 2>/dev/null")
assert_contains "journalctl returns logs" "$logs" "."

unit_logs=$(ssh_vm "journalctl -u ssh --no-pager -n 5 2>/dev/null")
assert_contains "Can filter by unit" "$unit_logs" "."

time_logs=$(ssh_vm "journalctl --since '10 minutes ago' --no-pager -n 5 2>/dev/null")
assert_contains "Can filter by time" "$time_logs" "."

assert "Persistent journal directory exists" ssh_vm "test -d /var/log/journal"

disk=$(ssh_vm "journalctl --disk-usage 2>/dev/null")
assert_contains "Disk usage is queryable" "$disk" "Archived and active journals"

report_results "Exercise 4"
