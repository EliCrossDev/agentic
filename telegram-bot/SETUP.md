# Telegram Bot Setup

Step-by-step guide to setting up the Agentic Telegram bot.

---

## Step 1: Create a Telegram Bot

1. Open Telegram and search for **@BotFather**
2. Send `/newbot`
3. Follow the prompts to name your bot
4. Copy the bot token (looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

---

## Step 2: Get Your Chat ID

1. Search for **@userinfobot** on Telegram
2. Send it any message
3. It will reply with your chat ID (a number like `123456789`)

---

## Step 3: Configure the Bot

Copy the environment template:

```bash
cp .env.example .env
```

Edit `.env` and fill in your values:

```
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
TMUX_SESSION_NAME=agentic
```

---

## Step 4: Install Dependencies

```bash
# Using Bun (recommended)
bun install

# Or using npm
npm install
```

---

## Step 5: Start the Bot

```bash
# Using Bun
bun run start

# Or using npm
npm start
```

The bot will start listening for messages. Send a message to your bot on Telegram to test it.

---

## Running in the Background

To keep the bot running after you close the terminal:

```bash
# Using nohup
nohup bun run start > /tmp/telegram-bot.log 2>&1 &

# Or using tmux (create a dedicated window)
tmux new-window -t agentic -n bot
tmux send-keys -t agentic:bot "cd /path/to/telegram-bot && bun run start" Enter
```

---

## Security Notes

- Keep your `.env` file private -- never commit it to version control
- The `TELEGRAM_CHAT_ID` setting restricts the bot to only respond to your messages
- The bot only has access to your local tmux session
