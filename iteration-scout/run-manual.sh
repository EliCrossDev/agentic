#!/bin/bash
# Iteration Scout - Manual Trigger
# Run on-demand using CLI authentication

echo ""
echo "  ================================================"
echo "     ITERATION SCOUT -- Manual Run                "
echo "  ================================================"
echo ""

# Ensure PATH includes common binary locations
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG_DIR="$HOME/.config/iteration-scout/logs"
PROMPT_FILE="$HOME/.config/iteration-scout/scout-prompt.md"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
LOG_FILE="$LOG_DIR/manual-$DATE.log"

# Detect Claude CLI location
CLAUDE_BIN=$(command -v claude 2>/dev/null || echo "$HOME/.local/bin/claude")

# Ensure directories exist
mkdir -p "$LOG_DIR"
mkdir -p "$HOME/.config/iteration-scout/output"

# Check if scout prompt exists
if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "  Error: Scout prompt not found!"
    echo "  Run install-scout.sh first to set up"
    exit 1
fi

if [[ ! -x "$CLAUDE_BIN" ]]; then
    echo "  Error: Claude CLI not found"
    echo "  Install with: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

echo "  Running Iteration Scout..."
echo "  Using CLI authentication"
echo "  Log: $LOG_FILE"
echo ""

# Run Claude in print mode (non-interactive)
"$CLAUDE_BIN" -p \
    --dangerously-skip-permissions \
    --add-dir "$HOME/code" \
    --add-dir "$HOME/.config/iteration-scout" \
    < "$PROMPT_FILE" 2>&1 | tee "$LOG_FILE"

echo ""
echo "  Scout complete! Check ~/.config/iteration-scout/output/ for PDFs."
echo ""
