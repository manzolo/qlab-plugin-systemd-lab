# Systemd Lab — Step-by-Step Guide

This guide walks you through **systemd**, the init system and service manager used by virtually all modern Linux distributions. Systemd is PID 1 — the first process started by the kernel, responsible for bringing up every other service on the system.

By the end of this lab you will understand how to manage services, write custom unit files, use timers as a modern cron replacement, work with journald for centralized logging, and analyze the boot process.

## Prerequisites

```bash
qlab run systemd-lab
qlab shell systemd-lab
cloud-init status --wait
```

## Credentials

- **Username:** `labuser` / **Password:** `labpass`

## Lab Environment

The VM comes with pre-configured:
- `sample.service` — a service that logs continuously to `/home/labuser/sample.log`
- `sample.timer` — triggers `sample-timer.service` every 5 minutes
- Journald configured for persistent logging

---

## Exercise 01 — Systemd Anatomy

**Goal:** Understand how systemd manages the system.

Systemd replaces the old SysVinit scripts with a unified, parallel, dependency-based system. Everything systemd manages is a "unit" — services, timers, mounts, sockets, and targets are all unit types.

### 1.1 Verify systemd is PID 1

```bash
ps -p 1 -o comm=
```

**Expected output:**
```
systemd
```

### 1.2 System state

```bash
systemctl status
```

### 1.3 List running units

```bash
systemctl list-units --type=service --state=running
```

### 1.4 List all unit types

```bash
systemctl -t help
```

**Expected output includes:** service, socket, target, timer, mount, etc.

### 1.5 Check system state

```bash
systemctl is-system-running
```

**Expected output:** `running` or `degraded`

**Verification:** systemd is PID 1 and the system is running.

---

## Exercise 02 — Service Management

**Goal:** Start, stop, enable, and disable services.

Services are the most common unit type. Understanding the difference between "active" (running right now) and "enabled" (starts at boot) is fundamental.

### 2.1 Check sample.service

```bash
systemctl status sample.service
```

### 2.2 Stop the service

```bash
sudo systemctl stop sample.service
systemctl is-active sample.service
```

**Expected output:** `inactive`

### 2.3 Start it again

```bash
sudo systemctl start sample.service
systemctl is-active sample.service
```

**Expected output:** `active`

### 2.4 Restart

```bash
sudo systemctl restart sample.service
```

### 2.5 Enable/disable at boot

```bash
systemctl is-enabled sample.service
sudo systemctl disable sample.service
systemctl is-enabled sample.service
```

**Expected output:** `disabled`

```bash
sudo systemctl enable sample.service
systemctl is-enabled sample.service
```

**Expected output:** `enabled`

### 2.6 View the unit file

```bash
systemctl cat sample.service
```

**Verification:** You can stop/start/restart services and toggle boot behavior.

---

## Exercise 03 — Unit Files

**Goal:** Write a custom service unit file.

Unit files define how systemd manages a service. They live in `/etc/systemd/system/` (admin-created) or `/lib/systemd/system/` (package-provided). The three main sections are `[Unit]` (metadata), `[Service]` (how to run), and `[Install]` (boot integration).

### 3.1 Explore unit file locations

```bash
ls /etc/systemd/system/
ls /lib/systemd/system/ | head -20
```

### 3.2 Read the sample.service unit file

```bash
systemctl cat sample.service
```

### 3.3 Create a custom service

```bash
cat << 'EOF' | sudo tee /etc/systemd/system/hello.service
[Unit]
Description=Hello World Service
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Hello from systemd at $(date)" >> /tmp/hello-systemd.log'
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF
```

### 3.4 Reload systemd

```bash
sudo systemctl daemon-reload
```

### 3.5 Run the custom service

```bash
sudo systemctl start hello.service
cat /tmp/hello-systemd.log
```

**Expected output:**
```
Hello from systemd at ...
```

### 3.6 Clean up

```bash
sudo systemctl stop hello.service 2>/dev/null
sudo rm -f /etc/systemd/system/hello.service /tmp/hello-systemd.log
sudo systemctl daemon-reload
```

**Verification:** Custom service runs and produces output.

---

## Exercise 04 — Journald and Logging

**Goal:** Use journalctl to query system logs.

Journald is systemd's centralized logging system. Unlike traditional syslog (text files in /var/log/), journald stores structured binary data that can be queried efficiently by unit, time, priority, and more.

### 4.1 View recent logs

```bash
journalctl --no-pager -n 20
```

### 4.2 Filter by unit

```bash
journalctl -u sample.service --no-pager -n 10
```

### 4.3 Filter by time

```bash
journalctl --since "5 minutes ago" --no-pager -n 10
```

### 4.4 Filter by priority

```bash
journalctl -p err --no-pager -n 10
```

Priority levels: emerg(0), alert(1), crit(2), err(3), warning(4), notice(5), info(6), debug(7).

### 4.5 Follow logs in real-time

```bash
journalctl -f -u sample.service &
sleep 3
kill %1 2>/dev/null
```

### 4.6 Check persistent logging

```bash
ls /var/log/journal/
```

### 4.7 Disk usage

```bash
journalctl --disk-usage
```

**Verification:** journalctl can filter by unit, time, and priority.

---

## Exercise 05 — Timers

**Goal:** Use systemd timers as a modern cron replacement.

Timers are units that trigger other units at specified times or intervals. They offer advantages over cron: dependency management, logging via journald, randomized delays to prevent thundering herd, and persistent timers that catch up on missed runs.

### 5.1 List active timers

```bash
systemctl list-timers --no-pager
```

### 5.2 Check the sample timer

```bash
systemctl status sample.timer
systemctl cat sample.timer
```

### 5.3 Create a custom timer

```bash
cat << 'EOF' | sudo tee /etc/systemd/system/custom.service
[Unit]
Description=Custom Timer Job

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo "Timer fired at $(date)" >> /tmp/custom-timer.log'
EOF

cat << 'EOF' | sudo tee /etc/systemd/system/custom.timer
[Unit]
Description=Custom Timer (every minute)

[Timer]
OnCalendar=*-*-* *:*:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

### 5.4 Enable and start

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now custom.timer
```

### 5.5 Verify it's scheduled

```bash
systemctl list-timers --no-pager | grep custom
```

### 5.6 Wait and check

```bash
sleep 65
cat /tmp/custom-timer.log
```

### 5.7 Clean up

```bash
sudo systemctl disable --now custom.timer
sudo rm -f /etc/systemd/system/custom.service /etc/systemd/system/custom.timer /tmp/custom-timer.log
sudo systemctl daemon-reload
```

**Verification:** Timer triggers the service on schedule.

---

## Exercise 06 — Targets and Boot

**Goal:** Understand boot targets and analyze startup performance.

Targets are groups of units — they replace the old runlevels. `multi-user.target` is equivalent to runlevel 3 (text mode), `graphical.target` is runlevel 5 (GUI).

### 6.1 Check default target

```bash
systemctl get-default
```

**Expected output:** `multi-user.target`

### 6.2 List targets

```bash
systemctl list-units --type=target --no-pager
```

### 6.3 View dependencies

```bash
systemctl list-dependencies multi-user.target --no-pager | head -20
```

### 6.4 Analyze boot time

```bash
systemd-analyze
```

**Expected output:**
```
Startup finished in ...kernel... + ...userspace... = ...
```

### 6.5 Blame — slowest units

```bash
systemd-analyze blame --no-pager | head -10
```

### 6.6 Critical chain

```bash
systemd-analyze critical-chain --no-pager
```

**Verification:** Default target is multi-user, boot analysis tools work.

---

## Troubleshooting

### Service won't start
```bash
systemctl status <service>
journalctl -u <service> --no-pager -n 30
```

### "Failed to enable unit"
```bash
# Check for syntax errors in the unit file
systemd-analyze verify /etc/systemd/system/<service>
# Reload after any changes
sudo systemctl daemon-reload
```

### Packages not installed
```bash
cloud-init status --wait
```
