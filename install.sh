#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Agentic Installer -- macOS and Linux
# Installs scripts to ~/.local/bin/ and sets up initial configuration
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config"
CONFIG_FILE="$CONFIG_DIR/agents-projects.json"

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}  ═══════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}     AGENTIC -- Multi-Agent Development Environment ${NC}"
    echo -e "${CYAN}${BOLD}  ═══════════════════════════════════════════════════${NC}"
    echo ""
}

info()    { echo -e "  ${CYAN}[INFO]${NC} $1"; }
success() { echo -e "  ${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "  ${YELLOW}[WARN]${NC} $1"; }
fail()    { echo -e "  ${RED}[FAIL]${NC} $1"; exit 1; }

# ─── Detect OS ────────────────────────────────────────────────────────────────

detect_os() {
    case "$(uname -s)" in
        Darwin*) OS="macos" ;;
        Linux*)  OS="linux" ;;
        *)       fail "Unsupported operating system: $(uname -s). Use macOS or Linux." ;;
    esac
    info "Detected OS: $OS"
}

# ─── Check Dependencies ──────────────────────────────────────────────────────

check_dependency() {
    local cmd="$1"
    local name="$2"
    local install_hint="$3"

    if command -v "$cmd" &>/dev/null; then
        success "$name is installed"
        return 0
    else
        warn "$name is not installed"
        echo -e "    ${GRAY}Install with: ${install_hint}${NC}"
        return 1
    fi
}

check_dependencies() {
    info "Checking dependencies..."
    echo ""

    local missing=0

    # tmux
    if ! check_dependency tmux "tmux" \
        "$([ "$OS" = "macos" ] && echo "brew install tmux" || echo "sudo apt install tmux  OR  sudo yum install tmux")"; then
        missing=1
    fi

    # jq
    if ! check_dependency jq "jq" \
        "$([ "$OS" = "macos" ] && echo "brew install jq" || echo "sudo apt install jq  OR  sudo yum install jq")"; then
        missing=1
    fi

    # git
    if ! check_dependency git "git" \
        "$([ "$OS" = "macos" ] && echo "xcode-select --install" || echo "sudo apt install git  OR  sudo yum install git")"; then
        missing=1
    fi

    # Claude CLI
    if ! check_dependency claude "Claude CLI" \
        "npm install -g @anthropic-ai/claude-code  (requires Claude Pro subscription)"; then
        missing=1
    fi

    echo ""

    if [ "$missing" -eq 1 ]; then
        warn "Some dependencies are missing. Install them and re-run this script."
        echo ""
        read -p "  Continue anyway? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# ─── Find Script Source Directory ─────────────────────────────────────────────

find_scripts_dir() {
    # If running from a cloned repo, scripts are in ./scripts/
    SCRIPT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -d "$SCRIPT_SOURCE/scripts" ]; then
        SCRIPTS_DIR="$SCRIPT_SOURCE/scripts"
        TEMPLATES_DIR="$SCRIPT_SOURCE/templates"
    else
        fail "Cannot find scripts/ directory. Run this from the agentic repo root."
    fi
}

# ─── Install Scripts ─────────────────────────────────────────────────────────

install_scripts() {
    info "Installing scripts to $INSTALL_DIR/ ..."
    mkdir -p "$INSTALL_DIR"

    local scripts=(
        "agentic"
        "agentic-stats"
        "agentic-session-stats"
        "agentic-pane-stats"
        "agentic-relay"
        "agentic-relay-status"
    )

    for script in "${scripts[@]}"; do
        if [ -f "$SCRIPTS_DIR/$script" ]; then
            cp "$SCRIPTS_DIR/$script" "$INSTALL_DIR/$script"
            chmod +x "$INSTALL_DIR/$script"
            success "Installed $script"
        else
            warn "Script not found: $script (skipping)"
        fi
    done

    # Check PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo ""
        warn "$INSTALL_DIR is not in your PATH."
        echo -e "    ${GRAY}Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):${NC}"
        echo -e "    ${GRAY}  export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
        echo ""
    fi
}

# ─── Install Config ──────────────────────────────────────────────────────────

install_config() {
    mkdir -p "$CONFIG_DIR"

    if [ -f "$CONFIG_FILE" ]; then
        info "Config already exists at $CONFIG_FILE (not overwriting)"
    else
        if [ -f "$TEMPLATES_DIR/agents-projects.json" ]; then
            cp "$TEMPLATES_DIR/agents-projects.json" "$CONFIG_FILE"
            success "Created config at $CONFIG_FILE"
        else
            # Create minimal config
            cat > "$CONFIG_FILE" << 'EOF'
{
  "projects": [
    {
      "name": "MyProject",
      "main_dir": "~/code/MyProject",
      "specialists": [
        "~/code/myproject-frontend",
        "~/code/myproject-backend",
        "~/code/myproject-tests"
      ]
    }
  ]
}
EOF
            success "Created default config at $CONFIG_FILE"
        fi
    fi
}

# ─── Install tmux Config ─────────────────────────────────────────────────────

install_tmux_config() {
    if [ -f "$HOME/.tmux.conf" ]; then
        info "tmux config already exists at ~/.tmux.conf (not overwriting)"
        echo -e "    ${GRAY}See templates/tmux.conf for recommended settings${NC}"
    else
        if [ -f "$TEMPLATES_DIR/tmux.conf" ]; then
            cp "$TEMPLATES_DIR/tmux.conf" "$HOME/.tmux.conf"
            success "Installed tmux config to ~/.tmux.conf"
        fi
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    print_header
    detect_os
    find_scripts_dir
    echo ""
    check_dependencies
    echo ""
    install_scripts
    echo ""
    install_config
    echo ""
    install_tmux_config
    echo ""

    echo -e "${GREEN}${BOLD}  ═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}     Installation Complete                          ${NC}"
    echo -e "${GREEN}${BOLD}  ═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    echo ""
    echo -e "  1. Edit your project config:"
    echo -e "     ${CYAN}nano ~/.config/agents-projects.json${NC}"
    echo ""
    echo -e "  2. Set up git worktrees for your project:"
    echo -e "     ${CYAN}cd ~/code/MyProject${NC}"
    echo -e "     ${CYAN}git worktree add ../myproject-frontend${NC}"
    echo -e "     ${CYAN}git worktree add ../myproject-backend${NC}"
    echo -e "     ${CYAN}git worktree add ../myproject-tests${NC}"
    echo ""
    echo -e "  3. Launch agentic:"
    echo -e "     ${CYAN}agentic${NC}"
    echo ""
    echo -e "  ${GRAY}Documentation: see docs/ directory or README.md${NC}"
    echo ""
}

main "$@"
