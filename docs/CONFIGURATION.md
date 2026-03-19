# Configuration Guide

---

## Project Configuration

All project configuration lives in `~/.config/agents-projects.json`.

### Basic Structure

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
  ]
}
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Display name for the project. Used in menus and logs. |
| `main_dir` | Yes | Path to the main project directory. The QB agent operates here. |
| `specialists` | Yes | Array of paths to specialist directories (usually git worktrees). |

### Multiple Projects

Add more entries to the `projects` array:

```json
{
  "projects": [
    {
      "name": "WebApp",
      "main_dir": "~/code/webapp",
      "specialists": [
        "~/code/webapp-frontend",
        "~/code/webapp-backend",
        "~/code/webapp-tests"
      ]
    },
    {
      "name": "MobileApp",
      "main_dir": "~/code/mobile",
      "specialists": [
        "~/code/mobile-ios",
        "~/code/mobile-android",
        "~/code/mobile-shared"
      ]
    }
  ]
}
```

See `examples/agents-projects-full.json` for a more complete example.

---

## Global Settings

Add a `.settings` key to your config:

```json
{
  "projects": [ ... ],
  ".settings": {
    "slow_mode": false,
    "dangerous_mode": false,
    "auto_relay": true
  }
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `slow_mode` | `false` | Stagger agent startup (wait for each to load before starting next) |
| `dangerous_mode` | `false` | Pass `--dangerously-skip-permissions` to Claude CLI |
| `auto_relay` | `false` | Enable auto-relay (QB prompt distribution via file watcher) |

---

## Agent Role Definitions

Each specialist can have a role definition that tells Claude what it should focus on. There are two approaches:

### Option 1: Agent Markdown Files (Recommended)

Create `.claude/agents/` in the specialist's worktree directory with a markdown file:

```
~/code/project-frontend/.claude/agents/frontend.md
```

```markdown
---
name: frontend
description: Frontend developer agent
---

# Frontend Developer

## Role
You are the frontend developer. Handle all React components, styling, and client-side logic.

## Expertise
- React / TypeScript
- CSS / Tailwind
- State management (Zustand, Redux)

## Files You Own
src/components/
src/pages/
src/styles/

## Guidelines
1. Follow existing component patterns
2. Write tests for new components
3. Do not modify backend or API code
```

### Option 2: Settings JSON Files

Create a JSON file with agent settings:

```json
{
  "agentRole": "Backend Developer",
  "systemPromptPrefix": "You are the BACKEND DEVELOPER agent. Your domain: API endpoints, database, authentication, server-side logic.",
  "permissions": {
    "allow": [
      "Bash(npm run:*)",
      "Bash(npm test:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)"
    ]
  }
}
```

See `examples/settings/` for complete examples for different agent types:

- `settings-backend.json` -- Backend developer permissions
- `settings-frontend.json` -- Frontend developer permissions
- `settings-dsp.json` -- DSP engineer permissions
- `settings-reviewer.json` -- Code reviewer (read-only) permissions

---

## Setting Up Git Worktrees

### Creating Worktrees

From your main project directory:

```bash
cd ~/code/my-project

# Create worktrees for each specialist
git worktree add ../my-project-frontend
git worktree add ../my-project-backend
git worktree add ../my-project-tests
```

Each worktree gets its own branch automatically. You can also specify a branch:

```bash
git worktree add ../my-project-frontend feature/frontend
```

### Listing Worktrees

```bash
git worktree list
```

### Removing Worktrees

```bash
git worktree remove ../my-project-frontend
```

### Merging Specialist Work

After specialists finish, merge their branches in the main directory:

```bash
cd ~/code/my-project
git merge my-project-frontend
git merge my-project-backend
git merge my-project-tests
```

---

## Tmux Configuration

Agentic works with any tmux configuration, but the included `templates/tmux.conf` provides a good starting point:

- `Ctrl+a` as prefix (instead of `Ctrl+b`)
- Mouse support enabled
- Alt+arrow keys for pane switching
- Alt+number for window switching
- Increased scrollback buffer (50,000 lines)
- Clean status bar styling

Install it:

```bash
cp templates/tmux.conf ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

---

## Environment Variables

You can set environment variables per specialist using the `envrc-template`:

```bash
export CLAUDE_AGENT_ROLE="frontend"
export PROJECT_NAME="MyProject"
```

Place this as `.envrc` in the specialist's worktree directory if using direnv, or source it in your shell profile.
