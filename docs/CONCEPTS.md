# Core Concepts

This document explains the architecture and key ideas behind Agentic.

---

## The QB/Specialist Model

Agentic uses a **Quarterback (QB) + Specialist** architecture inspired by how real development teams work.

### QB (Quarterback)

The QB is the coordinator agent. It runs in the top tmux pane and has one job: **break work into specialist-scoped tasks and dispatch them**.

The QB does NOT write code. It:

1. Receives your high-level request
2. Analyzes what needs to be done
3. Identifies which specialists are needed
4. Writes targeted prompts for each specialist
5. Dispatches prompts to specialist panes
6. Monitors progress
7. Reports results and coordinates merges

### Specialists

Specialist agents run in the bottom panes. Each specialist is scoped to a specific domain:

- **Frontend** -- React components, styling, client-side logic
- **Backend** -- API endpoints, database, server-side logic
- **Tests** -- Integration tests, unit tests, QA
- **DSP** -- Audio processing, algorithms (for audio projects)
- **DevOps** -- CI/CD, deployment, infrastructure

Each specialist operates in its own **git worktree**, so they can all modify files in parallel without conflicts.

### Why This Works

- **Parallel execution** -- All specialists work simultaneously instead of sequentially
- **Scoped context** -- Each agent only loads the files relevant to its domain, reducing token usage
- **Cache efficiency** -- Smaller, focused contexts mean higher cache hit rates
- **Clean separation** -- No agent accidentally breaks another's work

---

## Git Worktrees

Git worktrees allow multiple working directories to share a single git repository. Each worktree has its own branch and working tree, but they all share the same `.git` history.

```
~/code/my-app/              <-- main directory (QB)
~/code/my-app-frontend/     <-- worktree (Frontend specialist)
~/code/my-app-backend/      <-- worktree (Backend specialist)
~/code/my-app-tests/        <-- worktree (Tests specialist)
```

Create worktrees with:

```bash
cd ~/code/my-app
git worktree add ../my-app-frontend
git worktree add ../my-app-backend
git worktree add ../my-app-tests
```

When specialists finish their work and commit, changes can be merged back in the main directory.

---

## Auto-Relay

Auto-relay automates the dispatch of prompts from QB to specialists.

### Without Auto-Relay

1. You type a request to the QB
2. QB writes separate prompts for each specialist
3. You manually copy each prompt to the correct specialist pane

### With Auto-Relay

1. You type a request to the QB
2. QB writes `.prompt` files to a queue directory (`/tmp/agentic-relay/{project}/queue/`)
3. The `agentic-relay` watcher process detects new prompts
4. Prompts are automatically sent to the correct specialist panes via `tmux send-keys`
5. No manual intervention needed

The relay watcher runs as a background process. It checks for a `READY` trigger file, then distributes all `.prompt` files based on a pane mapping (`pane-map.json`).

### Prompt File Format

```
/tmp/agentic-relay/MyProject/queue/
  001-frontend.prompt    <-- sent to frontend pane
  002-backend.prompt     <-- sent to backend pane
  003-tests.prompt       <-- sent to tests pane
  READY                  <-- trigger file
```

---

## Cost Tracking

Agentic tracks token usage per agent and per session. This provides:

- **Per-agent breakdown** -- See how many tokens each specialist consumed
- **Session totals** -- Total input, output, and cached tokens
- **Cost estimates** -- Dollar estimates based on Claude pricing
- **Savings comparison** -- How much you saved compared to running everything through a single agent

### Why Multi-Agent Is Cheaper

When multiple specialists work independently:

- Each has a smaller context window (fewer input tokens)
- Cache hit rates are higher (same files stay in cache longer)
- Parallel work means less total context growth over time

A single agent doing everything sequentially would accumulate a massive context, paying full price for all those tokens on every turn.

### Viewing Stats

```bash
# Current session stats
agentic-stats

# Session history
agentic-stats --history

# Toggle tmux display
agentic-stats --toggle
```

---

## TeamCreate

TeamCreate is the Claude CLI's built-in mechanism for spawning agent teams. Agentic leverages this concept but uses tmux panes instead, giving you full visibility into each agent's work.

The key difference:

- **TeamCreate** -- Agents run as background processes, communicating via messages
- **Agentic** -- Agents run in visible tmux panes, with a file-based relay system

Agentic's approach lets you watch every agent work in real time, intervene if needed, and see exactly what each agent is doing.

---

## Project Profiles

You can configure multiple projects in `~/.config/agents-projects.json`. Each project defines:

- A **name** for display and selection
- A **main directory** where the QB operates
- A list of **specialist directories** (worktrees)

Switch between projects with `agentic --switch` or by selecting from the interactive menu.

---

## Slow Mode

On resource-constrained systems, starting all agents simultaneously can cause issues. Slow mode staggers agent startup, waiting for each agent to fully initialize before starting the next one.

Enable with:

```bash
agentic --slow
```

Or set it permanently in your config:

```json
{
  ".settings": {
    "slow_mode": true
  }
}
```
