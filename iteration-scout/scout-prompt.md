# Nightly Iteration Scout

## Step 0: Check Project Filter

**FIRST**, check if a project filter config exists at `~/.config/iteration-scout/projects.json`.

If the file exists, read it. It controls which projects to scout:
```json
{
  "mode": "include",
  "projects": ["project-name-1", "project-name-2"]
}
```

- `"mode": "include"` -- ONLY scout the listed projects (ignore everything else)
- `"mode": "exclude"` -- Scout ALL projects EXCEPT the listed ones
- If the file doesn't exist OR `"mode": "all"` -- scout everything (default behavior)

Project names are matched against directory names (case-insensitive, partial match OK).

## Step 1: Discover Projects

Known project locations:
- ~/code/
- ~/projects/

Scan these locations for ALL directories. These are the main projects (not worktrees). Apply the project filter from Step 0 -- if a filter is active, skip projects that don't match.

Skip directories that are clearly worktrees/variants (names ending in -ui, -dsp, -backend, -testing, -devops, -integration, -design, -review, -tests, -ai, -engine, or containing numbers like -2).

**IMPORTANT:** Only scan projects that CURRENTLY EXIST. Do not reference or recommend iterations for projects that have been deleted or renamed.

**Project name accuracy:** Use the EXACT directory name as the project name in all reports.

**Understanding each project:** For each project directory found, read documentation files to understand what the project does:
- CLAUDE.md, README.md, PRD.md (primary sources)
- Any other .md files in the root directory
- .claude/agents/*.md files (agent identity files)
- package.json, setup.py, or other config files
- Comments in main code files if needed

## Step 2: Research Each Project

For each project, use web search to find from the past 7 days:

1. Competitor updates -- new releases, features, announcements from similar products
2. Community pain points -- Reddit, forums, Twitter complaints about existing tools in this space
3. New tech -- libraries, APIs, techniques relevant to this project

Adapt search terms based on what the project actually is.

## Step 3: Generate PDFs

Delete everything in ~/.config/iteration-scout/output/ first, then create formatted PDFs.

**PDF GENERATION METHOD:**
Use HTML to PDF conversion. Write an HTML file with inline CSS, then convert to PDF using:
```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --headless --disable-gpu --print-to-pdf=output.pdf --no-pdf-header-footer input.html
```

If Chrome is not available, fall back to `wkhtmltopdf` or `weasyprint`.

**IMPORTANT:** Delete all intermediate HTML files after converting to PDF.

Each report includes:
- **Page 1 (Briefing)** -- Quick-glance summary with metrics, key findings, and a QB-ready command
- **Page 2+ (Deep Dive)** -- Full market analysis, community signals, technical opportunities

**QB Command:** Each project PDF includes a ready-to-paste command for the QB that contains:
- IMPLEMENT: The specific feature or task
- WHAT IT DOES: 3-5 concrete technical deliverables
- WHY: Market signal connection
- REFERENCE: Links to relevant sources
- SPECIALISTS NEEDED: Which agents to involve
- INSTRUCTIONS: Directions for the QB

**Code Audit Mode:** If no good iteration exists for a project, the scout switches to code audit mode -- scanning for security issues, redundant code, performance problems, and code quality issues.

## Step 4: Validate Quality

Before finishing, validate every project PDF to ensure QB Commands have all required fields and substantive content.

## Step 5: Report

Print summary of what you did: projects scanned, PDFs generated, any errors.
