#!/bin/bash
# Iteration Scout Installer
# Sets up the scout prompt and output directories

set -euo pipefail

echo ""
echo "  ================================================"
echo "     ITERATION SCOUT -- Setup                     "
echo "  ================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config/iteration-scout"

# 1. Create directories
echo "  Setting up directories..."
mkdir -p "$CONFIG_DIR/logs"
mkdir -p "$CONFIG_DIR/output"

# 2. Copy scout prompt
echo "  Installing scout prompt..."
cp "$SCRIPT_DIR/scout-prompt.md" "$CONFIG_DIR/scout-prompt.md"

echo ""
echo "  Setup complete."
echo ""
echo "  Scout prompt: $CONFIG_DIR/scout-prompt.md"
echo "  Output dir:   $CONFIG_DIR/output/"
echo "  Logs dir:     $CONFIG_DIR/logs/"
echo ""
echo "  Next steps:"
echo "    1. Edit $CONFIG_DIR/scout-prompt.md"
echo "       Update 'Known project locations' to match your setup"
echo ""
echo "    2. Run manually:"
echo "       bash $SCRIPT_DIR/run-manual.sh"
echo ""
echo "    3. (Optional) Set up scheduled runs:"
echo "       - macOS: Create a LaunchAgent plist"
echo "       - Linux: Add a cron job"
echo ""
