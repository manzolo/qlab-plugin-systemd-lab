#!/usr/bin/env bash
# systemd-lab run script — boots a VM for practicing systemd service management, timers, and journald

set -euo pipefail

PLUGIN_NAME="systemd-lab"
SSH_PORT=2237

echo "============================================="
echo "  systemd-lab: Systemd Service Management Lab"
echo "============================================="
echo ""
echo "  This lab demonstrates:"
echo "    1. systemd service lifecycle management"
echo "    2. Custom unit files (services, timers, oneshot)"
echo "    3. Timer scheduling (modern cron replacement)"
echo "    4. Journal log queries with journalctl"
echo ""

# Source QLab core libraries
if [[ -z "${QLAB_ROOT:-}" ]]; then
    echo "ERROR: QLAB_ROOT not set. Run this plugin via 'qlab run ${PLUGIN_NAME}'."
    exit 1
fi

for lib_file in "$QLAB_ROOT"/lib/*.bash; do
    # shellcheck source=/dev/null
    [[ -f "$lib_file" ]] && source "$lib_file"
done

# Configuration
WORKSPACE_DIR="${WORKSPACE_DIR:-.qlab}"
LAB_DIR="lab"
IMAGE_DIR="$WORKSPACE_DIR/images"
CLOUD_IMAGE_URL=$(get_config CLOUD_IMAGE_URL "https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img")
CLOUD_IMAGE_FILE="$IMAGE_DIR/ubuntu-22.04-minimal-cloudimg-amd64.img"
MEMORY="${QLAB_MEMORY:-$(get_config DEFAULT_MEMORY 1024)}"

# Ensure directories exist
mkdir -p "$LAB_DIR" "$IMAGE_DIR"

# Step 1: Download cloud image if not present
# Cloud images are pre-built OS images designed for cloud environments.
# They are minimal and expect cloud-init to configure them on first boot.
info "Step 1: Cloud image"
if [[ -f "$CLOUD_IMAGE_FILE" ]]; then
    success "Cloud image already downloaded: $CLOUD_IMAGE_FILE"
else
    echo ""
    echo "  Cloud images are pre-built OS images designed for cloud environments."
    echo "  They are minimal and expect cloud-init to configure them on first boot."
    echo ""
    info "Downloading Ubuntu cloud image..."
    echo "  URL: $CLOUD_IMAGE_URL"
    echo "  This may take a few minutes depending on your connection."
    echo ""
    check_dependency curl || exit 1
    curl -L -o "$CLOUD_IMAGE_FILE" "$CLOUD_IMAGE_URL" || {
        error "Failed to download cloud image."
        echo "  Check your internet connection and try again."
        exit 1
    }
    success "Cloud image downloaded: $CLOUD_IMAGE_FILE"
fi
echo ""

# Step 2: Create cloud-init configuration
# cloud-init reads user-data to configure the VM on first boot:
#   - creates users, installs packages, writes config files, runs commands
info "Step 2: Cloud-init configuration"
echo ""
echo "  cloud-init will:"
echo "    - Create a user 'labuser' with SSH access"
echo "    - Install systemd tools and utilities"
echo "    - Create sample services and timers"
echo "    - Configure journald for persistent logging"
echo ""

cat > "$LAB_DIR/user-data" <<'USERDATA'
#cloud-config
hostname: systemd-lab
package_update: true
users:
  - name: labuser
    plain_text_passwd: labpass
    lock_passwd: false
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - "__QLAB_SSH_PUB_KEY__"
ssh_pwauth: true
packages:
  - systemd
  - curl
  - net-tools
write_files:
  - path: /etc/profile.d/cloud-init-status.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      if command -v cloud-init >/dev/null 2>&1; then
        status=$(cloud-init status 2>/dev/null)
        if echo "$status" | grep -q "running"; then
          printf '\033[1;33m'
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "  Cloud-init is still running..."
          echo "  Some packages and services may not be ready yet."
          echo "  Run 'cloud-init status --wait' to wait for completion."
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          printf '\033[0m\n'
        fi
      fi
  - path: /etc/motd.raw
    content: |
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m
        \033[1;32msystemd-lab\033[0m — \033[1mSystemd Service Management Lab\033[0m
      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m

        \033[1;33mObjectives:\033[0m
          • manage systemd services (start, stop, enable, disable)
          • create custom unit files (services, timers, oneshot)
          • configure systemd timers as cron replacements
          • query and filter logs with journalctl

        \033[1;33mService Commands:\033[0m
          \033[0;32msudo systemctl status sample.service\033[0m    sample status
          \033[0;32msudo systemctl list-units --type=service\033[0m all services
          \033[0;32msudo systemctl list-timers\033[0m              active timers
          \033[0;32msudo systemctl daemon-reload\033[0m            reload units

        \033[1;33mJournal Commands:\033[0m
          \033[0;32msudo journalctl -u sample.service\033[0m      service logs
          \033[0;32msudo journalctl -u sample.service -f\033[0m   follow live
          \033[0;32msudo journalctl --since "5 min ago"\033[0m    recent logs
          \033[0;32msudo journalctl -p err\033[0m                 errors only

        \033[1;33mSample Files:\033[0m
          \033[0;32mcat ~/sample.log\033[0m                       service output
          \033[0;32mcat ~/timer.log\033[0m                        timer output

        \033[1;33mCredentials:\033[0m  \033[1;36mlabuser\033[0m / \033[1;36mlabpass\033[0m
        \033[1;33mExit:\033[0m         type '\033[1;31mexit\033[0m'

      \033[1;36m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m
  - path: /etc/systemd/system/sample.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Sample service for systemd lab
      After=network.target

      [Service]
      Type=simple
      User=labuser
      ExecStart=/bin/bash -c 'while true; do echo "Sample service running at $(date)" >> /home/labuser/sample.log; sleep 10; done'
      Restart=always
      RestartSec=3

      [Install]
      WantedBy=multi-user.target
  - path: /etc/systemd/system/sample.timer
    permissions: '0644'
    content: |
      [Unit]
      Description=Sample timer for systemd lab

      [Timer]
      OnCalendar=*:0/5
      Persistent=true

      [Install]
      WantedBy=timers.target
  - path: /etc/systemd/system/sample-timer.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Sample timer action
      After=network.target

      [Service]
      Type=oneshot
      User=labuser
      ExecStart=/bin/bash -c 'echo "Timer executed at $(date)" >> /home/labuser/timer.log'
runcmd:
  - chmod -x /etc/update-motd.d/*
  - sed -i 's/^#\?PrintMotd.*/PrintMotd yes/' /etc/ssh/sshd_config
  - sed -i 's/^session.*pam_motd.*/# &/' /etc/pam.d/sshd
  - printf '%b\n' "$(cat /etc/motd.raw)" > /etc/motd
  - rm -f /etc/motd.raw
  - systemctl restart sshd
  - mkdir -p /var/log/journal
  - systemd-tmpfiles --create --prefix /var/log/journal
  - systemctl restart systemd-journald
  - systemctl daemon-reload
  - systemctl enable sample.service
  - systemctl start sample.service
  - systemctl enable sample.timer
  - systemctl start sample.timer
  - chown -R labuser:labuser /home/labuser
  - echo "=== systemd-lab VM is ready! ==="
USERDATA

# Inject the SSH public key into user-data
sed -i "s|__QLAB_SSH_PUB_KEY__|${QLAB_SSH_PUB_KEY:-}|g" "$LAB_DIR/user-data"

cat > "$LAB_DIR/meta-data" <<METADATA
instance-id: ${PLUGIN_NAME}-001
local-hostname: ${PLUGIN_NAME}
METADATA

success "Created cloud-init files in $LAB_DIR/"
echo ""

# Step 3: Generate cloud-init ISO
# QEMU reads cloud-init data from a small ISO image (CD-ROM).
# We use genisoimage to create it with the 'cidata' volume label.
info "Step 3: Cloud-init ISO"
echo ""
echo "  QEMU reads cloud-init data from a small ISO image (CD-ROM)."
echo "  We use genisoimage to create it with the 'cidata' volume label."
echo ""

CIDATA_ISO="$LAB_DIR/cidata.iso"
check_dependency genisoimage || {
    warn "genisoimage not found. Install it with: sudo apt install genisoimage"
    exit 1
}
genisoimage -output "$CIDATA_ISO" -volid cidata -joliet -rock \
    "$LAB_DIR/user-data" "$LAB_DIR/meta-data" 2>/dev/null
success "Created cloud-init ISO: $CIDATA_ISO"
echo ""

# Step 4: Create overlay disk
# An overlay disk uses copy-on-write (COW) on top of the base image.
# The original cloud image stays untouched; all writes go to the overlay.
info "Step 4: Overlay disk"
echo ""
echo "  An overlay disk uses copy-on-write (COW) on top of the base image."
echo "  This means:"
echo "    - The original cloud image stays untouched"
echo "    - All writes go to the overlay file"
echo "    - You can reset the lab by deleting the overlay"
echo ""

OVERLAY_DISK="$LAB_DIR/${PLUGIN_NAME}-disk.qcow2"
if [[ -f "$OVERLAY_DISK" ]]; then
    info "Removing previous overlay disk..."
    rm -f "$OVERLAY_DISK"
fi
create_overlay "$CLOUD_IMAGE_FILE" "$OVERLAY_DISK" "${QLAB_DISK_SIZE:-}"
echo ""

# Step 5: Boot the VM in background
info "Step 5: Starting VM in background"
echo ""
echo "  The VM will run in background with:"
echo "    - Serial output logged to .qlab/logs/$PLUGIN_NAME.log"
echo "    - SSH access on port $SSH_PORT"
echo ""

start_vm "$OVERLAY_DISK" "$CIDATA_ISO" "$MEMORY" "$PLUGIN_NAME" "$SSH_PORT"

echo ""
echo "============================================="
echo "  systemd-lab: VM is booting"
echo "============================================="
echo ""
echo "  Credentials:"
echo "    Username: labuser"
echo "    Password: labpass"
echo ""
echo "  Connect via SSH (wait ~60s for boot + package install):"
echo "    qlab shell ${PLUGIN_NAME}"
echo ""
echo "  View boot log:"
echo "    qlab log ${PLUGIN_NAME}"
echo ""
echo "  Stop VM:"
echo "    qlab stop ${PLUGIN_NAME}"
echo ""
echo "  Tip: override resources with environment variables:"
echo "    QLAB_MEMORY=4096 QLAB_DISK_SIZE=30G qlab run ${PLUGIN_NAME}"
echo "============================================="
