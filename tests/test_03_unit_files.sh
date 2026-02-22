#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
echo ""; echo "${BOLD}Exercise 3 — Unit Files${RESET}"; echo ""

assert "System unit directory exists" ssh_vm "test -d /etc/systemd/system"
assert "Lib unit directory exists" ssh_vm "test -d /lib/systemd/system"

# Create custom service
ssh_vm "sudo tee /etc/systemd/system/hello.service > /dev/null << 'EOF'
[Unit]
Description=Hello Test Service
[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo hello-test >> /tmp/hello-systemd.log'
RemainAfterExit=no
[Install]
WantedBy=multi-user.target
EOF" >/dev/null

assert "daemon-reload succeeds" ssh_vm "sudo systemctl daemon-reload"
assert "Custom service starts" ssh_vm "sudo systemctl start hello.service"

log_content=$(ssh_vm "cat /tmp/hello-systemd.log 2>/dev/null")
assert_contains "Custom service produced output" "$log_content" "hello-test"

# Cleanup
ssh_vm "sudo rm -f /etc/systemd/system/hello.service /tmp/hello-systemd.log; sudo systemctl daemon-reload" >/dev/null 2>&1

report_results "Exercise 3"
