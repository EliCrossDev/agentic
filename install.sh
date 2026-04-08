#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Agentic Installer -- macOS
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
        *)       fail "Unsupported operating system: $(uname -s). Use macOS or Windows (via WSL)." ;;
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

ensure_brew() {
    # Check if brew exists but isn't in PATH (common on fresh Apple Silicon Macs)
    if command -v brew &>/dev/null; then
        return 0
    elif [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        return 0
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
        return 0
    fi

    # Check if user has admin/sudo access (required for Homebrew install)
    if ! sudo -n true 2>/dev/null && ! dseditgroup -o checkmember -m "$(whoami)" admin &>/dev/null; then
        echo ""
        echo -e "  ${RED}${BOLD}Your user account is not an administrator.${NC}"
        echo -e "  ${RED}Homebrew (and tmux/node) require admin access to install.${NC}"
        echo ""
        echo -e "  ${BOLD}Fix:${NC} Open ${CYAN}System Settings → Users & Groups${NC}"
        echo -e "       Make your account an admin, then re-run this install."
        echo ""
        echo -e "  ${BOLD}Or:${NC} Ask an admin on this Mac to run:"
        echo -e "       ${CYAN}brew install tmux node && npm install -g @anthropic-ai/claude-code${NC}"
        echo ""
        fail "Admin access required. Fix the above and re-run."
    fi

    info "Installing Homebrew (you may be prompted for your password)..."
    # Redirect /dev/tty to stdin so sudo can prompt for password inside curl|bash
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
    # Set up brew in current session
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if command -v brew &>/dev/null; then
        success "Installed Homebrew"
        return 0
    else
        fail "Could not install Homebrew. Install it manually: https://brew.sh"
    fi
}

auto_install() {
    local cmd="$1"
    local name="$2"

    if command -v "$cmd" &>/dev/null; then
        success "$name is installed"
        return 0
    fi

    info "Installing $name..."
    if [ "$OS" = "macos" ]; then
        ensure_brew
        brew install "$cmd" 2>/dev/null && success "Installed $name" && return 0
    else
        if command -v apt-get &>/dev/null; then
            sudo apt-get update -qq 2>/dev/null
            sudo apt-get install -y "$cmd" 2>/dev/null && success "Installed $name" && return 0
        elif command -v yum &>/dev/null; then
            sudo yum install -y "$cmd" 2>/dev/null && success "Installed $name" && return 0
        fi
    fi

    fail "Could not install $name."
}

check_dependencies() {
    info "Installing dependencies..."
    echo ""

    # macOS: everything via brew. Linux: via apt/yum.
    auto_install tmux "tmux"
    auto_install jq "jq"
    auto_install git "git"

    # Node.js (needed for Claude CLI)
    if ! command -v node &>/dev/null; then
        auto_install node "Node.js"
    else
        success "Node.js is installed"
    fi

    # Claude CLI
    if ! command -v claude &>/dev/null; then
        info "Installing Claude CLI..."
        npm install -g @anthropic-ai/claude-code 2>/dev/null && success "Installed Claude CLI" || fail "Claude CLI install failed. Run: npm install -g @anthropic-ai/claude-code"
    else
        success "Claude CLI is installed"
    fi

    echo ""
}

# ─── Find Script Source Directory (local clone) ───────────────────────────────

find_scripts_dir() {
    # BASH_SOURCE[0] is empty or /dev/stdin when piped via curl | bash
    local script_path="${BASH_SOURCE[0]:-}"
    if [ -n "$script_path" ] && [ "$script_path" != "/dev/stdin" ] && [ -f "$script_path" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "$script_path")" && pwd)"
        if [ -d "$script_dir/scripts" ] && [ -f "$script_dir/scripts/agentic" ]; then
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
    info "Installing agentic to $INSTALL_DIR/ ..."
    mkdir -p "$INSTALL_DIR"

    if [ "$INSTALL_MODE" = "local" ] && [ -f "$SCRIPTS_DIR/agentic" ]; then
        # Local mode: copy from cloned repo
        cp "$SCRIPTS_DIR/agentic" "$INSTALL_DIR/agentic"
        chmod +x "$INSTALL_DIR/agentic"
        success "Installed agentic"
    else
        # Remote mode: download binary from latest GitHub release
        info "Downloading agentic..."
        if [ "$OS" = "macos" ]; then
            local RELEASE_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/agentic-macos-arm64.tar.gz"
        else
            local RELEASE_URL="https://github.com/${GITHUB_REPO}/releases/latest/download/agentic-linux.tar.gz"
        fi
        local TEMP_DIR=$(mktemp -d)

        if curl -fsSL "$RELEASE_URL" -o "$TEMP_DIR/agentic.tar.gz" 2>/dev/null; then
            tar -xzf "$TEMP_DIR/agentic.tar.gz" -C "$TEMP_DIR"
            if [ -f "$TEMP_DIR/agentic" ]; then
                cp "$TEMP_DIR/agentic" "$INSTALL_DIR/agentic"
                chmod +x "$INSTALL_DIR/agentic"
                success "Installed agentic"
            else
                fail "Binary not found in release archive."
            fi
            rm -rf "$TEMP_DIR"
        else
            fail "Could not download agentic. Check your internet connection."
        fi
    fi

    # Ensure PATH is set in ALL relevant shell profiles (fixes "command not found" on fresh installs)
    local path_line='export PATH="$HOME/.local/bin:$PATH"'
    local profiles_updated=0

    if [ "${SHELL:-}" = "/bin/zsh" ] || [ -f "$HOME/.zshrc" ] || [ -f "$HOME/.zprofile" ]; then
        # Add to .zprofile (login shells — new Terminal windows)
        if ! grep -q '\.local/bin' "$HOME/.zprofile" 2>/dev/null; then
            echo "$path_line" >> "$HOME/.zprofile"
            profiles_updated=1
        fi
        # Add to .zshrc (interactive shells — subshells, tmux panes)
        if ! grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
            echo "$path_line" >> "$HOME/.zshrc"
            profiles_updated=1
        fi
    elif [ "${SHELL:-}" = "/bin/bash" ]; then
        if ! grep -q '\.local/bin' "$HOME/.bashrc" 2>/dev/null; then
            echo "$path_line" >> "$HOME/.bashrc"
            profiles_updated=1
        fi
        if ! grep -q '\.local/bin' "$HOME/.bash_profile" 2>/dev/null; then
            echo "$path_line" >> "$HOME/.bash_profile"
            profiles_updated=1
        fi
    fi

    if [ "$profiles_updated" -eq 1 ]; then
        success "Added PATH entry to shell profiles"
    elif [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
        success "PATH already configured"
    fi

    # Source for this session
    export PATH="$HOME/.local/bin:$PATH"
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
  "projects": [],
  "settings": {
    "slow_mode": false,
    "dangerous_mode": true,
    "auto_relay": true,
    "solo_mode": true,
    "multi_projects": ""
  }
}
EOF
        success "Created default config at $CONFIG_FILE"
    fi

    # Create agentic-config.json for cost tracker display
    if [ ! -f "$CONFIG_DIR/agentic-config.json" ]; then
        cat > "$CONFIG_DIR/agentic-config.json" << 'EOF'
{
  "show_token_stats": true
}
EOF
        success "Enabled cost tracker display"
    fi

    # Create initial metrics file so cost calculator shows from first launch
    if [ ! -f "$CONFIG_DIR/agentic-metrics.json" ]; then
        echo '{}' > "$CONFIG_DIR/agentic-metrics.json"
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

# ─── Configure Claude Code for TeamCreate ────────────────────────────────────

configure_claude_settings() {
    local claude_dir="$HOME/.claude"
    local settings_file="$claude_dir/settings.json"
    local hook_script="$claude_dir/hooks/capture-tokens.sh"

    mkdir -p "$claude_dir/hooks"
    # Create capture-tokens hook if it doesn't exist
    if [ ! -f "$hook_script" ]; then
        cat > "$hook_script" << 'HOOKEOF'
#!/bin/bash
# Capture token usage from Claude Code sessions for cost tracking
# Reads session data from stdin, appends to metrics file
INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0
METRICS_FILE="$HOME/.config/agentic-metrics.json"
[ ! -f "$METRICS_FILE" ] && echo '{}' > "$METRICS_FILE"
exit 0
HOOKEOF
        chmod +x "$hook_script"
    fi

    # Build the desired settings with teammateMode and Stop hook
    local needs_update=false

    if [ ! -f "$settings_file" ]; then
        echo '{}' > "$settings_file"
        needs_update=true
    fi

    # Check all required fields
    if ! jq -e '.teammateMode' "$settings_file" &>/dev/null; then needs_update=true; fi
    if ! jq -e '.hooks.Stop' "$settings_file" &>/dev/null; then needs_update=true; fi
    if ! jq -e '.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$settings_file" &>/dev/null; then needs_update=true; fi
    if ! jq -e '.skipDangerousModePermissionPrompt' "$settings_file" &>/dev/null; then needs_update=true; fi
    if ! jq -e '.statusLine' "$settings_file" &>/dev/null; then needs_update=true; fi

    if [ "$needs_update" = true ]; then
        local tmp_file
        tmp_file=$(mktemp)
        local status_cmd='input=$(cat); model=$(echo \"$input\" | jq -r '"'"'.model.display_name // \"Claude\"'"'"'); remaining=$(echo \"$input\" | jq -r '"'"'.context_window.remaining_percentage // empty'"'"'); time=$(date +\"%H:%M:%S\"); date=$(date \"+%b %d\"); if [ -n \"$remaining\" ]; then r=$(printf \"%.0f\" \"$remaining\"); if [ \"$r\" -gt 50 ] 2>/dev/null; then ctx=$(printf \"\\033[32m%s%%\\033[0m\" \"$r\"); elif [ \"$r\" -gt 20 ] 2>/dev/null; then ctx=$(printf \"\\033[33m%s%%\\033[0m\" \"$r\"); else ctx=$(printf \"\\033[31m%s%%\\033[0m\" \"$r\"); fi; else ctx=\"\\033[2m--\\033[0m\"; fi; printf \"\\033[36m%s\\033[0m \\033[2m|\\033[0m %s \\033[2m|\\033[0m \\033[34m%s\\033[0m \\033[2m%s\\033[0m\" \"$model\" \"$ctx\" \"$time\" \"$date\"'
        jq --arg hook "$hook_script" --arg statuscmd "$status_cmd" '
            .teammateMode = "tmux" |
            .theme = "dark" |
            .skipDangerousModePermissionPrompt = true |
            .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1" |
            .statusLine //= {"type": "command", "command": $statuscmd} |
            .hooks.Stop //= [{"hooks": [{"type": "command", "command": $hook}]}] |
            if (.hooks.Stop | map(.hooks[]? | select(.command == $hook)) | length) == 0
            then .hooks.Stop += [{"hooks": [{"type": "command", "command": $hook}]}]
            else . end
        ' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"
        success "Agent teams, status line, and token capture configured"
    else
        success "All settings already configured"
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
    configure_claude_settings
    echo ""

    echo -e "${GREEN}${BOLD}  ═══════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}     Installation Complete                          ${NC}"
    echo -e "${GREEN}${BOLD}  ═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    echo ""
    echo -e "  Just run:"
    echo -e "     ${CYAN}agentic${NC}"
    echo ""
    echo -e "  The built-in menu will guide you through creating your first project."
    echo ""
    echo -e "  ${GRAY}Documentation: https://github.com/${GITHUB_REPO}${NC}"
    echo ""
}

main "$@"
