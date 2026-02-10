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
| SSH     | 2237      | 22      |

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

1. **Service inspection**: Run `sudo systemctl status sample.service` and read the output — identify PID, memory usage, and recent log lines
2. **Stop and start**: Stop the sample service with `sudo systemctl stop sample.service`, verify it stopped, then start it again
3. **Create a custom service**: Write a new unit file in `/etc/systemd/system/myapp.service` that runs a simple script, then enable and start it
4. **Timer management**: Inspect `sample.timer` with `sudo systemctl list-timers` and `sudo systemctl status sample.timer`, then modify the `OnCalendar=` schedule
5. **Journal queries**: Use `sudo journalctl -u sample.service --since "5 minutes ago"` to filter logs by time, then try filtering by priority with `-p err`
6. **Service dependencies**: Edit your custom service to add `After=network.target` and `Requires=network.target`, then verify the dependency tree with `systemctl list-dependencies`

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
