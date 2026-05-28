#!/usr/bin/env bash
# create_swap.sh
# Create and enable a 4GB swap file on Debian-based systems.
# Run as root (sudo ./create_swap.sh)

set -euo pipefail

SWAPFILE="/swapfile"
SIZE_GB=4
SIZE_BYTES="$(( SIZE_GB * 1024 * 1024 * 1024 ))"
FSTAB_LINE="$SWAPFILE none swap sw 0 0"
SWAPPINESS_VALUE=10   # change or set to empty to skip

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo." >&2
  exit 1
fi

# Check if swapfile already exists or swap already using that file
if swapon --summary | grep -q "^$SWAPFILE\b"; then
  echo "Swapfile $SWAPFILE is already active." >&2
  exit 1
fi

if [ -f "$SWAPFILE" ]; then
  echo "File $SWAPFILE already exists. Remove or rename it and re-run this script." >&2
  exit 1
fi

# Ensure enough free space on the filesystem that will host the swapfile
available_bytes=$(df --output=avail -B1 / | tail -n1)
if [ "$available_bytes" -lt "$SIZE_BYTES" ]; then
  echo "Not enough free space to create a ${SIZE_GB}G swapfile on /." >&2
  echo "Available: $available_bytes bytes, required: $SIZE_BYTES bytes." >&2
  exit 1
fi

echo "Creating ${SIZE_GB}G swapfile at $SWAPFILE ..."

# Prefer fallocate if available and supported
if command -v fallocate >/dev/null 2>&1; then
  if fallocate -l "${SIZE_GB}G" "$SWAPFILE"; then
    echo "Created swapfile with fallocate."
  else
    echo "fallocate failed; falling back to dd." >&2
    rm -f "$SWAPFILE"
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=$(( SIZE_GB * 1024 )) status=progress
  fi
else
  dd if=/dev/zero of="$SWAPFILE" bs=1M count=$(( SIZE_GB * 1024 )) status=progress
fi

# Secure permissions
chmod 600 "$SWAPFILE"
chown root:root "$SWAPFILE"

# Format as swap
mkswap "$SWAPFILE"

# Enable it now
swapon "$SWAPFILE"

echo "Swap enabled:"
swapon --show

# Add to /etc/fstab if not present
if ! grep -qF "$SWAPFILE" /etc/fstab; then
  echo "$FSTAB_LINE" >> /etc/fstab
  echo "Added $SWAPFILE to /etc/fstab"
else
  echo "$SWAPFILE already exists in /etc/fstab"
fi

# Optionally set swappiness now and persistently
if [ -n "${SWAPPINESS_VALUE:-}" ]; then
  if [ "$SWAPPINESS_VALUE" -ge 0 ] 2>/dev/null && [ "$SWAPPINESS_VALUE" -le 100 ] 2>/dev/null; then
    sysctl -w vm.swappiness="$SWAPPINESS_VALUE"
    # Persist if not already set in /etc/sysctl.conf
    if ! grep -qE '^\s*vm\.swappiness\s*=' /etc/sysctl.conf; then
      echo "vm.swappiness=$SWAPPINESS_VALUE" >> /etc/sysctl.conf
      echo "Persisted vm.swappiness=$SWAPPINESS_VALUE in /etc/sysctl.conf"
    else
      echo "vm.swappiness is set in /etc/sysctl.conf already; please edit if you want to change it."
    fi
  else
    echo "Skipping swappiness: $SWAPPINESS_VALUE is not between 0 and 100." >&2
  fi
fi

echo "All done."
