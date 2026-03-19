# Agentic - Multi-Agent Development Environment

**Coordinate multiple Claude Code agents in parallel using tmux, with a Quarterback (QB) directing specialist agents to build software faster.**

Agentic turns a single terminal into a multi-agent war room. One QB agent breaks down your request into specialist tasks, and each specialist works independently in its own tmux pane -- all visible, all in parallel.

```
+---------------------------------------------------------------+
|                     QB (Quarterback)                          |
|  Receives your prompt, breaks it into specialist tasks,       |
|  dispatches work, monitors progress, merges results.          |
+---------------------------------------------------------------+
|  Frontend       |  Backend        |  Tests          |  ...    |
|  Agent           |  Agent           |  Agent           |         |
|  Working on      |  Working on      |  Working on      |         |
|  React components|  API endpoints   |  Integration     |         |
|  in its own      |  in its own      |  tests in its    |         |
|  worktree        |  worktree        |  own worktree    |         |
+------------------+------------------+------------------+---------+
```

---

## Features

- **QB + Specialist Architecture** -- One coordinator agent dispatches work to N specialist agents, each scoped to a domain (frontend, backend, DSP, tests, etc.)
- **Tmux-Based Layout** -- Every agent runs in a visible tmux pane. Watch them all work simultaneously.
- **Git Worktrees** -- Each specialist operates in its own git worktree, eliminating merge conflicts during parallel work.
- **Auto-Relay** -- QB writes prompt files, the relay watcher distributes them to specialist panes automatically. No copy-paste needed.
- **Cost Tracking** -- Real-time token usage and cost estimates displayed per-agent and per-session in tmux borders.
- **Project Profiles** -- Configure multiple projects with different specialist configurations. Switch between them instantly.
- **Settings Per Specialist** -- Custom Claude settings (permissions, system prompts, roles) for each agent.
- **Slow Mode** -- Staggered agent startup for systems with limited resources.
- **Session History** -- Track token usage across sessions with cost comparison (multi-agent vs. single-agent estimates).
- **Cross-Platform** -- macOS and Linux (bash) support.

---

## Requirements

- **macOS or Linux**
- **tmux** (terminal multiplexer)
- **Claude CLI** -- requires a Claude Pro or Team subscription (`claude` command)
- **jq** (JSON processor)
- **git** (for worktree support)

---

## Installation

### One-Command Install (macOS / Linux)

```bash
curl -fsSL https://raw.githubusercontent.com/EliCrossDev/agentic/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/EliCrossDev/agentic.git
cd agentic
bash install.sh
```

---

## Quick Start

### 1. Configure a Project

Edit `~/.config/agents-projects.json`:

```json
{
  "projects": [
    {
      "name": "MyApp",
      "main_dir": "~/code/MyApp",
      "specialists": [
        "~/code/myapp-frontend",
        "~/code/myapp-backend",
        "~/code/myapp-tests"
      ]
    }
  ]
}
```

Each specialist directory should be a **git worktree** of the main repo:

```bash
cd ~/code/MyApp
git worktree add ../myapp-frontend
git worktree add ../myapp-backend
git worktree add ../myapp-tests
```

### 2. Define Agent Roles

Create `.claude/agents/` in each specialist worktree with a markdown file defining the agent's role. See `templates/.claude/agents/example-agent.md` for the format.

Alternatively, place Claude settings JSON files in `~/.config/` to configure permissions and system prompts per specialist (see `examples/settings/`).

### 3. Launch

```bash
agentic
```

This opens an interactive menu to select your project. Agentic creates a tmux session with:
- Pane 1 (top): QB agent
- Panes 2-N (bottom): Specialist agents

### 4. Send Your First Prompt

Type your request into the QB pane. The QB will:
1. Analyze the request
2. Break it into specialist tasks
3. Dispatch each task to the appropriate specialist pane
4. Monitor progress
5. Report when all specialists are done

---

## How It Works

### The QB Model

The Quarterback (QB) is the coordinator agent. It occupies the top pane and has one job: break work into specialist-scoped tasks and dispatch them. The QB does not write code itself.

Each specialist agent runs Claude Code in its own tmux pane, scoped to a specific domain (frontend, backend, tests, etc.) and working in its own git worktree. Specialists can read and write files, run commands, and commit changes independently.

### Auto-Relay

When auto-relay is enabled, the QB writes `.prompt` files to a queue directory. The `agentic-relay` watcher process detects new prompts and automatically sends them to the correct specialist panes via `tmux send-keys`. This eliminates manual copy-paste between panes.

Flow:
```
You --> QB pane --> writes .prompt files --> relay watcher --> specialist panes
```

### Cost Tracking

Agentic tracks token usage per agent per session. The `agentic-session-stats` widget shows real-time costs in the tmux status bar, comparing multi-agent costs against a single-agent estimate to show savings from parallel, cache-efficient operation.

### Git Worktrees

Each specialist works in a separate git worktree of the same repository. This means:
- No merge conflicts during parallel work
- Each agent has its own working directory
- Changes merge cleanly when specialists finish
- The QB can trigger merges from the main directory

---

## CLI Reference

```
agentic [OPTIONS]

Options:
  -f, --fresh         Start a fresh session (default behavior)
  -s, --switch        Switch to a different project
  -a, --all           Load ALL agents for ALL projects
  -l, --list          List configured projects
  -p, --project N     Load a specific project by number or name
  -k, --kill          Kill all tmux sessions
  --no-kill           Add project to existing session
  --slow              Staggered agent startup
  --fast              Quick agent startup (override slow mode)
  -h, --help          Show help
```

### Companion Scripts

| Script | Purpose |
|--------|---------|
| `agentic-stats` | View detailed token usage and cost reports |
| `agentic-session-stats` | Tmux status bar widget for session costs |
| `agentic-pane-stats` | Tmux border widget for per-pane token stats |
| `agentic-relay` | Auto-relay watcher for QB prompt distribution |
| `agentic-relay-status` | Tmux status bar widget for relay state |

---

## Configuration

### Project Config (`~/.config/agents-projects.json`)

```json
{
  "projects": [
    {
      "name": "ProjectName",
      "main_dir": "~/code/project",
      "specialists": [
        "~/code/project-frontend",
        "~/code/project-backend",
        "~/code/project-tests"
      ]
    }
  ],
  ".settings": {
    "slow_mode": false,
    "dangerous_mode": false,
    "auto_relay": true
  }
}
```

### Agent Settings (per specialist)

Place JSON files in `~/.config/` or in the specialist's `.claude/` directory:

```json
{
  "agentRole": "Backend Developer",
  "systemPromptPrefix": "You are the BACKEND DEVELOPER agent...",
  "permissions": {
    "allow": [
      "Bash(npm run:*)",
      "Bash(git commit:*)"
    ]
  }
}
```

See `examples/settings/` for complete examples.

For more details, see [docs/CONFIGURATION.md](docs/CONFIGURATION.md).

---

## Optional Integrations

### Telegram Bot

Control your agentic sessions remotely via Telegram. Send prompts, check status, and receive completion notifications from your phone.

See [telegram-bot/README.md](telegram-bot/README.md) for setup instructions.

### Iteration Scout

Automated nightly reports that scan your projects, research competitors, and suggest next iterations. Generates styled PDF briefings.

See [iteration-scout/README.md](iteration-scout/README.md) for setup instructions.

---

## Documentation

- [Quick Start Guide](docs/QUICKSTART.md) -- Get running in 5 minutes
- [Core Concepts](docs/CONCEPTS.md) -- QB, specialists, TeamCreate, auto-relay
- [Configuration Guide](docs/CONFIGURATION.md) -- Projects, agents, settings
- [Troubleshooting](docs/TROUBLESHOOTING.md) -- Common issues and fixes

---

## Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes
4. Test with at least one project configuration
5. Submit a pull request

For bug reports and feature requests, please open an issue.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
