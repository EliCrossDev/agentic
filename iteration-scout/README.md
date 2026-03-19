# Iteration Scout - Automated Project Reports

Get daily automated reports on all your projects with AI-powered insights.

---

## What It Does

Iteration Scout scans your projects, researches competitors and community trends, and generates styled PDF briefings with actionable next iterations. Each report includes:

- **Summary PDF** -- Overview of all projects with recommended iterations
- **Per-Project PDFs** -- Detailed analysis with QB-ready commands
- **Market Intelligence** -- Competitor updates, community pain points, new tech
- **Code Audits** -- When no iteration is needed, the scout audits your codebase instead

Reports are delivered as beautifully formatted PDFs to `~/.config/iteration-scout/output/`.

---

## Modes

### Manual Trigger (Free)

Run on-demand whenever you want:

```bash
bash run-manual.sh
```

Requires Claude CLI with an active subscription.

### Scheduled (Free)

Set up a daily run at a fixed time using your OS scheduler:

- **macOS**: LaunchAgent (see `install-scout.sh`)
- **Linux**: cron job

Requires your machine to be awake at the scheduled time.

---

## Setup

### 1. Install the Scout Prompt

```bash
bash install-scout.sh
```

This copies the scout prompt to `~/.config/iteration-scout/scout-prompt.md` and creates necessary directories.

### 2. Customize Project Locations

Edit `~/.config/iteration-scout/scout-prompt.md` and update the project locations to match your setup:

```markdown
Known project locations:
- ~/code/
- ~/projects/
```

### 3. Run Manually (Test)

```bash
bash run-manual.sh
```

Check `~/.config/iteration-scout/output/` for generated PDFs.

---

## Project Filtering

Control which projects get scanned by creating `~/.config/iteration-scout/projects.json`:

```json
{
  "mode": "include",
  "projects": ["project-name-1", "project-name-2"]
}
```

Modes:
- `"include"` -- Only scout the listed projects
- `"exclude"` -- Scout everything except the listed projects
- `"all"` -- Scout all projects (default)

---

## Output

Reports are saved to `~/.config/iteration-scout/output/`:

```
~/.config/iteration-scout/output/
  00-summary.pdf           -- Overview of all projects
  01-project-name.pdf      -- Detailed report for first project
  02-another-project.pdf   -- Detailed report for second project
```

---

## Logs

Check logs at `~/.config/iteration-scout/logs/`:

```bash
tail ~/.config/iteration-scout/logs/$(date +%Y-%m-%d).log
```
