# Troubleshooting

Common issues and how to fix them.

---

## Installation Issues

### "command not found: agentic"

The scripts are installed to `~/.local/bin/` which may not be in your PATH.

Fix:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Add this line to your `~/.bashrc` or `~/.zshrc` to make it permanent, then restart your terminal.

### "Need jq: brew install jq"

Agentic requires `jq` for JSON parsing. Install it:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# RHEL/CentOS
sudo yum install jq
```

---

## Tmux Issues

### "no server running" or "no sessions"

Tmux is not running. Agentic creates its own session, so just run `agentic` and it will start one.

If you get errors about an existing session:

```bash
agentic --kill
agentic
```

### Panes are too small

If you have many specialists, panes can become very small. Solutions:

1. Use a larger terminal window or maximize it
2. Reduce the number of specialists
3. Use tmux zoom (`Ctrl+a z`) to temporarily expand one pane

### Can't scroll in panes

Make sure mouse support is enabled in your tmux config:

```
set -g mouse on
```

Or use tmux's copy mode: `Ctrl+a [` then use arrow keys/Page Up/Page Down.

### Agents don't start in panes

1. Check that Claude CLI is installed: `claude --version`
2. Check that you're logged in: `claude` (should open interactive mode)
3. Check pane contents manually: `tmux capture-pane -t agentic:1.2 -p`

---

## Agent Issues

### QB doesn't dispatch to specialists

Make sure the QB's CLAUDE.md or system prompt instructs it to act as a coordinator. The QB should:

- NOT write code itself
- Break requests into specialist tasks
- Use `tmux send-keys` to dispatch (or write .prompt files for auto-relay)

### Specialists don't know their role

Ensure each specialist has a role definition in `.claude/agents/` or a settings JSON file. Without this, agents behave as generic Claude instances.

### "Permission denied" errors

If agents need to run specific commands, configure permissions in their settings:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run:*)",
      "Bash(git:*)"
    ]
  }
}
```

Or use `--dangerously-skip-permissions` (only for trusted projects):

```json
{
  ".settings": {
    "dangerous_mode": true
  }
}
```

---

## Auto-Relay Issues

### Prompts not being dispatched

1. Check relay status: `agentic-relay status`
2. Ensure the relay watcher is running: look for a `relay.pid` file in `/tmp/agentic-relay/{project}/`
3. Check the relay log: `cat /tmp/agentic-relay/{project}/relay.log`
4. Verify the pane map exists: `cat /tmp/agentic-relay/{project}/pane-map.json`

### "No pane mapping for specialist"

The specialist name in the `.prompt` filename must match a key in `pane-map.json`. Check that:

1. The prompt file is named correctly (e.g., `001-frontend.prompt`)
2. The pane map has a matching entry (e.g., `"frontend": "agentic:1.2"`)

### Relay watcher dies

Start it manually:

```bash
agentic-relay start --project MyProject
```

Check logs for errors:

```bash
tail -f /tmp/agentic-relay/MyProject/relay.log
```

---

## Cost Tracking Issues

### No stats showing

1. Check that metrics file exists: `ls ~/.config/agentic-metrics.json`
2. Check display is enabled: `agentic-stats --status`
3. If disabled, re-enable: `agentic-stats --on`

### Stats seem wrong

The token capture hook may not be running. Metrics are collected via tmux hooks that parse Claude's output. If your tmux config overrides these hooks, stats won't accumulate.

Reset and start fresh:

```bash
agentic-stats --reset
agentic --fresh
```

---

## Git Worktree Issues

### "fatal: is already checked out"

You're trying to create a worktree on a branch that's already checked out. Use a different branch name:

```bash
git worktree add ../my-project-frontend feature/frontend-work
```

### Merge conflicts after specialist work

If two specialists modified the same file:

```bash
cd ~/code/my-project
git merge my-project-frontend
# If conflict:
git merge my-project-backend   # this may conflict
# Resolve manually, then:
git add .
git commit -m "Merge specialist work"
```

To minimize this, scope specialists to non-overlapping file sets.

---

## General Tips

- **Kill everything and restart**: `agentic --kill && agentic`
- **View what's in a pane**: `tmux capture-pane -t agentic:1.2 -p | tail -20`
- **Check all panes**: `tmux list-panes -t agentic -a`
- **Logs**: Check `/tmp/agentic-relay/` for relay logs
- **Reset stats**: `agentic-stats --reset`
