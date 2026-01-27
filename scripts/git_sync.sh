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
  automations.yaml
  scripts.yaml
  button_card_templates.yaml
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

logger -t "$LOG_TAG" "Sync complete: $COPIED files updated"
