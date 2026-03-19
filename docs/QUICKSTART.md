# Quick Start Guide

Get Agentic running in 5 minutes.

---

## Prerequisites

Make sure you have these installed:

- **tmux** -- `brew install tmux` (macOS) or `sudo apt install tmux` (Linux)
- **jq** -- `brew install jq` (macOS) or `sudo apt install jq` (Linux)
- **git** -- likely already installed
- **Claude CLI** -- `npm install -g @anthropic-ai/claude-code` (requires Claude Pro subscription)

---

## Step 1: Install Agentic

```bash
git clone https://github.com/YOUR_USERNAME/agentic.git
cd agentic
bash install.sh
```

This copies the scripts to `~/.local/bin/` and creates a starter config at `~/.config/agents-projects.json`.

Make sure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Add that line to your `~/.bashrc` or `~/.zshrc` to make it permanent.

---

## Step 2: Set Up a Project

### Create the main project

```bash
mkdir -p ~/code/my-app
cd ~/code/my-app
git init
echo "# My App" > README.md
git add . && git commit -m "Initial commit"
```

### Create worktrees for specialists

```bash
git worktree add ../my-app-frontend
git worktree add ../my-app-backend
git worktree add ../my-app-tests
```

### Configure Agentic

Edit `~/.config/agents-projects.json`:

```json
{
  "projects": [
    {
      "name": "MyApp",
      "main_dir": "~/code/my-app",
      "specialists": [
        "~/code/my-app-frontend",
        "~/code/my-app-backend",
        "~/code/my-app-tests"
      ]
    }
  ]
}
```

---

## Step 3: Define Agent Roles (Optional)

Create a `.claude/agents/` directory in each specialist worktree with a role definition file. For example, in `~/code/my-app-frontend/.claude/agents/frontend.md`:

```markdown
# Frontend Developer

## Role
You are the frontend developer. You handle all React components, styling, and client-side logic.

## Expertise
- React / TypeScript
- CSS / Tailwind
- State management

## Guidelines
1. Follow the project's existing component patterns
2. Write tests for new components
3. Do not modify backend code
```

See `templates/.claude/agents/example-agent.md` for a full template.

---

## Step 4: Launch

```bash
agentic
```

Select your project from the menu. Agentic will:

1. Create a tmux session
2. Open the QB pane (top)
3. Open specialist panes (bottom row)
4. Start Claude Code in each pane

---

## Step 5: Send Your First Prompt

Click into the QB pane (top) and type:

```
Build a simple REST API with a /health endpoint and a React frontend that displays the health status. Include integration tests.
```

The QB will analyze this, create separate prompts for each specialist (frontend, backend, tests), and dispatch them.

Watch all agents work in parallel in their respective panes.

---

## What Next?

- Read [CONCEPTS.md](CONCEPTS.md) to understand the QB/specialist model
- Read [CONFIGURATION.md](CONFIGURATION.md) for advanced project setup
- Try `agentic --help` to see all CLI options
- Run `agentic-stats` after a session to see token usage and cost savings
