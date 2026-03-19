# Telegram Bot Integration

Control your Agentic sessions remotely via Telegram.

---

## What It Does

The Telegram bot lets you:

- Send prompts to the QB from your phone
- Check the status of running agents
- Start and stop relay dispatching
- Receive notifications when specialists finish
- View session stats and cost reports

---

## Requirements

- A Telegram account
- A Telegram Bot token (from @BotFather)
- Node.js / Bun runtime
- An active Agentic tmux session on the host machine

---

## Setup

See [SETUP.md](SETUP.md) for step-by-step setup instructions.

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `/status` | Show agent status |
| `/stop` | Stop current operation |
| `/restart` | Restart the bot |
| `/new` | Start a new conversation |
| `/resume` | Resume previous conversation |

Send any text message to forward it as a prompt to the QB pane.

---

## Architecture

The bot runs as a separate background process on your development machine. It:

1. Listens for Telegram messages
2. Translates commands into tmux operations
3. Captures pane output for status reports
4. Sends results back via Telegram

The bot communicates with Agentic purely through tmux -- it reads pane content and sends keystrokes, just like you would manually.
