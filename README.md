# systemd-lab — Systemd Service Management Lab

[![QLab Plugin](https://img.shields.io/badge/QLab-Plugin-blue)](https://github.com/manzolo/qlab)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey)](https://github.com/manzolo/qlab)

A [QLab](https://github.com/manzolo/qlab) plugin that boots a virtual machine pre-configured with sample systemd services and timers for practicing service management, unit files, and journald log analysis.

## Objectives

- Understand systemd service lifecycle (start, stop, enable, disable, restart)
- Create and edit custom systemd unit files (services, timers, oneshot)
- Configure systemd timers as a modern cron replacement
- Use journalctl to query and filter logs by unit, priority, and time range
- Manage service dependencies with `After=`, `Requires=`, `Wants=`

## How It Works

1. **Cloud image**: Downloads a minimal Ubuntu 22.04 cloud image (~250MB)
2. **Cloud-init**: Creates `user-data` with sample services, timers, and logging tools
3. **ISO generation**: Packs cloud-init files into a small ISO (cidata)
4. **Overlay disk**: Creates a COW disk on top of the base image (original stays untouched)
5. **QEMU boot**: Starts the VM in background with SSH port forwarding

## Credentials

- **Username:** `labuser`
- **Password:** `labpass`

## Ports

| Service | Host Port | VM Port |
|---------|-----------|---------|
| SSH     | dynamic   | 22      |

> All host ports are dynamically allocated. Use `qlab ports` to see the actual mappings.

## Pre-installed Services

| Unit | Type | Description |
|------|------|-------------|
| `sample.service` | simple (always running) | Writes a timestamped line to `/home/labuser/sample.log` every 10s |
| `sample.timer` | timer (every 5 min) | Triggers `sample-timer.service` on a calendar schedule |
| `sample-timer.service` | oneshot | Appends a timestamp to `/home/labuser/timer.log` |

## Usage

```bash
# Install the plugin
qlab install systemd-lab

# Run the lab
qlab run systemd-lab

# Wait ~60s for boot and package installation, then:

# Connect via SSH
qlab shell systemd-lab

# Inside the VM:
#   - Check sample service: sudo systemctl status sample.service
#   - View timer schedule: sudo systemctl list-timers
#   - Follow service logs: sudo journalctl -u sample.service -f
#   - Check timer logs: cat ~/timer.log

# Stop the VM
qlab stop systemd-lab
```

## Exercises

> **New to systemd?** See the [Step-by-Step Guide](guide.md) for complete walkthroughs with full examples.

| # | Exercise | What you'll do |
|---|----------|----------------|
| 1 | **Systemd Anatomy** | Explore unit files, service types, and systemctl basics |
| 2 | **Service Management** | Start, stop, enable, disable, and restart services |
| 3 | **Unit Files** | Create custom service unit files from scratch |
| 4 | **Journald and Logging** | Query logs with journalctl, filter by unit and priority |
| 5 | **Timers** | Create and manage systemd timers as cron replacements |
| 6 | **Targets and Boot** | Understand boot targets and service dependencies |

## Automated Tests

An automated test suite validates the exercises against a running VM:

```bash
# Start the lab first
qlab run systemd-lab
# Wait ~60s for cloud-init, then run all tests
qlab test systemd-lab
```

## Resetting

To start fresh, stop and re-run:

```bash
qlab stop systemd-lab
qlab run systemd-lab
```

Or reset the entire workspace:

```bash
qlab reset
```
