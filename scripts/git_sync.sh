#!/bin/bash
# ============================================================
# Git Sync Dashboard
# Pulls managed YAML files from GitHub into /config
# without touching any other HA configuration files.
# ============================================================

REPO="git@github.com:Dlaczak/tablet-dashboard.git"
TEMP_DIR="/tmp/dashboard-sync"
CONFIG_DIR="/config"
LOG_TAG="git_sync"

# Files to sync from repo into /config
FILES=(
  home.yaml
  security.yaml
  server.yaml
  weather.yaml
  printers.yaml
  media.yaml
  automations.yaml
  scripts.yaml
  button_card_templates_data.yaml
  tablet.yaml
)

# Directories to sync
DIRS=(
  scripts
)

logger -t "$LOG_TAG" "Starting dashboard sync..."

# Clone or pull
if [ -d "$TEMP_DIR/.git" ]; then
  cd "$TEMP_DIR" && git pull --ff-only 2>&1 | logger -t "$LOG_TAG"
else
  rm -rf "$TEMP_DIR"
  git clone "$REPO" "$TEMP_DIR" 2>&1 | logger -t "$LOG_TAG"
fi

if [ $? -ne 0 ]; then
  logger -t "$LOG_TAG" "ERROR: git operation failed"
  exit 1
fi

# Copy only managed files
COPIED=0
for f in "${FILES[@]}"; do
  if [ -f "$TEMP_DIR/$f" ]; then
    cp "$TEMP_DIR/$f" "$CONFIG_DIR/$f"
    COPIED=$((COPIED + 1))
  fi
done

# Copy directories
for d in "${DIRS[@]}"; do
  if [ -d "$TEMP_DIR/$d" ]; then
    mkdir -p "$CONFIG_DIR/$d"
    cp -r "$TEMP_DIR/$d/"* "$CONFIG_DIR/$d/"
    COPIED=$((COPIED + 1))
  fi
done

# Clean up renamed/removed files
if [ -f "$CONFIG_DIR/music.yaml" ]; then
  rm "$CONFIG_DIR/music.yaml"
  logger -t "$LOG_TAG" "Removed deprecated music.yaml"
fi

logger -t "$LOG_TAG" "Sync complete: $COPIED items updated"
