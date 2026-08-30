#!/usr/bin/env bash
# Pulls new/updated wallpapers from JaKooLit/Wallpaper-Bank into
# ~/Pictures/wallpapers, without touching anything already there that
# didn't come from upstream (Rusty's own AI-generated desert-* wallpapers
# etc. are left alone).
#
# Usage: sync-wallpapers.sh [--dry-run]
set -euo pipefail

REPO_URL="https://github.com/JaKooLit/Wallpaper-Bank.git"
CACHE_DIR="$HOME/.cache/wallpaper-sync/Wallpaper-Bank"
DEST_DIR="$HOME/Pictures/wallpapers"
DRY_RUN=false
[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

mkdir -p "$(dirname "$CACHE_DIR")" "$DEST_DIR"

if [ -d "$CACHE_DIR/.git" ]; then
  git -C "$CACHE_DIR" fetch --depth 1 origin main -q
  git -C "$CACHE_DIR" reset --hard origin/main -q
else
  rm -rf "$CACHE_DIR"
  git clone --depth 1 "$REPO_URL" "$CACHE_DIR" -q
fi

RSYNC_ARGS=(-a --ignore-existing)
$DRY_RUN && RSYNC_ARGS+=(--dry-run -v)

# Upstream layout: wallpapers/ (flat pack) + astralbed.png at repo root.
# --ignore-existing means this only ever ADDS new files, never overwrites
# or deletes anything already in ~/Pictures/wallpapers (including the
# non-upstream desert-* files noted in memory).
ADDED=$(rsync "${RSYNC_ARGS[@]}" --out-format="%n" \
  "$CACHE_DIR/wallpapers/" "$DEST_DIR/" 2>/dev/null | grep -v '/$' || true)

if [ -f "$CACHE_DIR/astralbed.png" ] && [ ! -f "$DEST_DIR/astralbed.png" ]; then
  if $DRY_RUN; then
    echo "astralbed.png"
  else
    cp "$CACHE_DIR/astralbed.png" "$DEST_DIR/astralbed.png"
  fi
  ADDED="${ADDED}"$'\n'"astralbed.png"
fi

ADDED=$(echo "$ADDED" | sed '/^$/d')
COUNT=$(echo -n "$ADDED" | grep -c . || true)

# Sanity check: flag (don't touch) any zero-byte file in the dest dir,
# matching the exact corruption pattern from the 2026-08-22 incident.
ZERO_BYTE=$(find "$DEST_DIR" -maxdepth 1 -type f -size 0 2>/dev/null || true)

if [ "$COUNT" -gt 0 ]; then
  echo "Added $COUNT new wallpaper(s):"
  echo "$ADDED"
  if ! $DRY_RUN && command -v notify-send >/dev/null; then
    notify-send "Wallpaper sync" "Added $COUNT new wallpaper(s) from Wallpaper-Bank"
  fi
else
  echo "No new wallpapers."
fi

if [ -n "$ZERO_BYTE" ]; then
  echo "WARNING: zero-byte files found in $DEST_DIR (possible corruption):"
  echo "$ZERO_BYTE"
  if ! $DRY_RUN && command -v notify-send >/dev/null; then
    notify-send -u critical "Wallpaper sync" "Zero-byte files detected in $DEST_DIR — check manually"
  fi
fi
