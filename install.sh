#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Agentic Installer -- macOS and Linux
# Supports both: curl -fsSL https://raw.githubusercontent.com/EliCrossDev/agentic/main/install.sh | bash
#            and: ./install.sh  (from a cloned repo)
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

GITHUB_REPO="EliCrossDev/agentic"
GITHUB_BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}"

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

    # curl (needed for remote download)
    if ! check_dependency curl "curl" \
        "$([ "$OS" = "macos" ] && echo "brew install curl" || echo "sudo apt install curl  OR  sudo yum install curl")"; then
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

# ─── Find Script Source Directory (local clone) ───────────────────────────────

find_scripts_dir() {
    # BASH_SOURCE[0] is empty or /dev/stdin when piped via curl | bash
    local script_path="${BASH_SOURCE[0]:-}"
    if [ -n "$script_path" ] && [ "$script_path" != "/dev/stdin" ] && [ -f "$script_path" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "$script_path")" && pwd)"
        if [ -d "$script_dir/scripts" ]; then
            SCRIPTS_DIR="$script_dir/scripts"
            TEMPLATES_DIR="$script_dir/templates"
            INSTALL_MODE="local"
            info "Installing from local clone: $script_dir"
            return 0
        fi
    fi
    # Fall back to remote download
    INSTALL_MODE="remote"
    info "Installing from GitHub: ${GITHUB_REPO}@${GITHUB_BRANCH}"
}

# ─── Download a file from GitHub ─────────────────────────────────────────────

download_file() {
    local remote_path="$1"
    local dest="$2"
    local url="${RAW_BASE}/${remote_path}"

    if curl -fsSL "$url" -o "$dest"; then
        return 0
    else
        warn "Failed to download: $url"
        return 1
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
        if [ "$INSTALL_MODE" = "local" ]; then
            if [ -f "$SCRIPTS_DIR/$script" ]; then
                cp "$SCRIPTS_DIR/$script" "$INSTALL_DIR/$script"
                chmod +x "$INSTALL_DIR/$script"
                success "Installed $script"
            else
                warn "Script not found: $script (skipping)"
            fi
        else
            # Remote mode: download from GitHub
            local dest="$INSTALL_DIR/$script"
            if download_file "scripts/$script" "$dest"; then
                chmod +x "$dest"
                success "Installed $script"
            else
                warn "Could not install $script (skipping)"
            fi
        fi
    done

    # Check PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo ""
        warn "$INSTALL_DIR is not in your PATH."
        echo -e "    ${GRAY}Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):${NC}"
        echo -e "    ${GRAY}  export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
        echo ""
        # Attempt to add to shell profile automatically
        local shell_profile=""
        if [ -n "${BASH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/bash" ]; then
            shell_profile="$HOME/.bashrc"
        elif [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL:-}" = "/bin/zsh" ]; then
            shell_profile="$HOME/.zshrc"
        fi
        if [ -n "$shell_profile" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_profile"
            success "Added PATH entry to $shell_profile (restart your shell or run: source $shell_profile)"
        fi
    fi
}

# ─── Install Config ──────────────────────────────────────────────────────────

install_config() {
    mkdir -p "$CONFIG_DIR"

    if [ -f "$CONFIG_FILE" ]; then
        info "Config already exists at $CONFIG_FILE (not overwriting)"
        return
    fi

    local config_written=0

    if [ "$INSTALL_MODE" = "local" ] && [ -f "$TEMPLATES_DIR/agents-projects.json" ]; then
        cp "$TEMPLATES_DIR/agents-projects.json" "$CONFIG_FILE"
        config_written=1
    elif [ "$INSTALL_MODE" = "remote" ]; then
        if download_file "templates/agents-projects.json" "$CONFIG_FILE"; then
            config_written=1
        fi
    fi

    if [ "$config_written" -eq 1 ]; then
        success "Created config at $CONFIG_FILE"
    else
        # Fallback: write minimal inline config
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
}

# ─── Install tmux Config ─────────────────────────────────────────────────────

install_tmux_config() {
    if [ -f "$HOME/.tmux.conf" ]; then
        info "tmux config already exists at ~/.tmux.conf (not overwriting)"
        echo -e "    ${GRAY}See templates/tmux.conf for recommended settings${NC}"
        return
    fi

    local tmux_conf_written=0

    if [ "$INSTALL_MODE" = "local" ] && [ -f "$TEMPLATES_DIR/tmux.conf" ]; then
        cp "$TEMPLATES_DIR/tmux.conf" "$HOME/.tmux.conf"
        tmux_conf_written=1
    elif [ "$INSTALL_MODE" = "remote" ]; then
        if download_file "templates/tmux.conf" "$HOME/.tmux.conf"; then
            tmux_conf_written=1
        fi
    fi

    if [ "$tmux_conf_written" -eq 1 ]; then
        success "Installed tmux config to ~/.tmux.conf"
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
    echo -e "  ${GRAY}Documentation: https://github.com/${GITHUB_REPO}${NC}"
    echo ""
}

main "$@"
