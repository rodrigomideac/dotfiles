#!/usr/bin/env bash
# Resize /swapfile. Defaults to 128G.
#
# The root filesystem here is XFS, which means the swapfile must be written with
# real allocated blocks. `fallocate` produces unwritten extents and swapon then
# fails with EINVAL, so this uses dd. That makes the run slow but correct.
#
# Context: with only 512M of swap against 62G of RAM the kernel had no room to
# reclaim under pressure and went straight to the OOM killer (2026-08-20).
set -euo pipefail

SWAPFILE=/swapfile
SIZE_GB="${1:-128}"

if [[ $EUID -ne 0 ]]; then
    echo "error: must run as root (try: sudo $0 ${SIZE_GB})" >&2
    exit 1
fi

if ! [[ $SIZE_GB =~ ^[0-9]+$ ]] || (( SIZE_GB < 1 )); then
    echo "error: size must be a positive integer number of GB, got '${SIZE_GB}'" >&2
    exit 1
fi

# Space check against the filesystem holding the swapfile, counting whatever the
# current swapfile already occupies as reclaimable.
target_dir=$(dirname "$SWAPFILE")
avail_mb=$(df -BM --output=avail "$target_dir" | tail -1 | tr -dc '0-9')
current_mb=0
[[ -f $SWAPFILE ]] && current_mb=$(( $(stat -c %s "$SWAPFILE") / 1024 / 1024 ))
need_mb=$(( SIZE_GB * 1024 ))
if (( avail_mb + current_mb < need_mb + 10240 )); then
    echo "error: need ${need_mb}M + 10G headroom, only $(( avail_mb + current_mb ))M available on ${target_dir}" >&2
    exit 1
fi

echo "==> Disabling current swap"
if swapon --show=NAME --noheadings | grep -qx "$SWAPFILE"; then
    swapoff "$SWAPFILE"
fi
rm -f "$SWAPFILE"

echo "==> Allocating ${SIZE_GB}G at ${SWAPFILE} (XFS: real blocks via dd, this takes a few minutes)"
dd if=/dev/zero of="$SWAPFILE" bs=1M count=$(( SIZE_GB * 1024 )) status=progress conv=fsync

echo "==> Formatting"
chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"

echo "==> Enabling"
swapon "$SWAPFILE"

echo "==> Ensuring fstab entry"
if ! grep -qE "^[[:space:]]*${SWAPFILE}[[:space:]]" /etc/fstab; then
    printf '%s\tswap\tswap\tdefaults\t0 0\n' "$SWAPFILE" >> /etc/fstab
    echo "    added"
else
    echo "    already present"
fi

echo
swapon --show
free -h
