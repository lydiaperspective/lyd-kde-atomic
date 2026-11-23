#!/usr/bin/env bash
set -Eeuo pipefail

# Keep the server image headless even if the base image's default target changes.
mkdir -p /etc/systemd/system
ln -sfn /usr/lib/systemd/system/multi-user.target /etc/systemd/system/default.target

# Fail the image build if the Cockpit web service was not actually installed.
for package in cockpit cockpit-ws cockpit-system cockpit-podman; do
  rpm -q "$package" >/dev/null || {
    echo "Required Cockpit package is missing from the server image: $package" >&2
    exit 1
  }
done

# Cockpit is socket-activated; cockpit.service is expected to start on demand.
test -f /usr/lib/systemd/system/cockpit.socket || {
  echo "cockpit.socket unit is missing from the server image." >&2
  exit 1
}
mkdir -p /etc/systemd/system/sockets.target.wants
ln -sfn /usr/lib/systemd/system/cockpit.socket /etc/systemd/system/sockets.target.wants/cockpit.socket

# Open Cockpit's standard HTTPS management port in firewalld's default zone.
if command -v firewall-offline-cmd >/dev/null 2>&1; then
  firewall-offline-cmd --add-service=cockpit
else
  echo "firewall-offline-cmd is missing; cannot configure the Cockpit firewall rule." >&2
  exit 1
fi

echo "Server image configured: headless multi-user target, Cockpit socket enabled, TCP 9090 allowed."
