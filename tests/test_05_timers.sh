#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 5 — Timers${RESET}"; echo ""

timers=$(ssh_vm "systemctl list-timers --no-pager 2>/dev/null")
assert_contains "list-timers works" "$timers" "NEXT|LEFT|LAST|PASSED"

timer_status=$(ssh_vm "systemctl is-active sample.timer 2>/dev/null" || echo "unknown")
assert_contains "sample.timer is active" "$timer_status" "active"

# Create custom timer
ssh_vm "sudo tee /etc/systemd/system/custom.service > /dev/null << 'EOF'
[Unit]
Description=Custom Timer Test
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo timer-test >> /tmp/custom-timer.log'
EOF
sudo tee /etc/systemd/system/custom.timer > /dev/null << 'EOF'
[Unit]
Description=Custom Timer
[Timer]
OnCalendar=*-*-* *:*:00
[Install]
WantedBy=timers.target
EOF" >/dev/null

ssh_vm "sudo systemctl daemon-reload" >/dev/null
assert "Enable custom timer" ssh_vm "sudo systemctl enable --now custom.timer"

custom_timers=$(ssh_vm "systemctl list-timers --no-pager 2>/dev/null")
assert_contains "Custom timer appears in list" "$custom_timers" "custom"

# Cleanup
ssh_vm "sudo systemctl disable --now custom.timer 2>/dev/null; sudo rm -f /etc/systemd/system/custom.service /etc/systemd/system/custom.timer /tmp/custom-timer.log; sudo systemctl daemon-reload" >/dev/null 2>&1

report_results "Exercise 5"
