# SpecSkills

Two agent skills for spec-first, senior-level software engineering. They work with Claude Code and with
any coding agent that supports the open [Agent Skills](https://github.com/agentskills/agentskills)
format (`SKILL.md` folders), and they fall back to plain project files for tools that don't.

## What's inside

| Skill | What it does |
|---|---|
| `senior-engineering` | The baseline for any code work: ask instead of guessing; design with the project's own rules plus SOLID, DRY and KISS/YAGNI, and no abstraction without a present need; rich domain entities; security as part of correctness; no confidential data in remote tool calls; tests that challenge business rules, the technical solution, performance and security, with every external dependency run for real through Testcontainers; code review; ADRs. |
| `spec-driven` | Runs a project spec-first as small, linked files: discovery, product spec, numbered EARS requirements with a traceability matrix, a tech spec with ADRs and a stack playbook, a stepwise plan, and review. Size, architecture and practices are decided with you at setup; later features are change folders merged into living specs; one agent, or a lead and a coder working through files. |

`spec-driven` builds on `senior-engineering`. Install both, and keep them side by side in the same
folder: `spec-driven` links to `../senior-engineering/`.

## Install

### 1. Get the files

```bash
git clone https://github.com/SLjavad/SpecSkills.git
```

### 2. Copy both folders into your tool's skills folder

| Tool | For you, in every project | For one project (commit it to share with a team) |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| OpenAI Codex | `~/.agents/skills/` | `.agents/skills/` |
| GitHub Copilot (VS Code, CLI, cloud agent) | `~/.copilot/skills/` | `.github/skills/` or `.agents/skills/` |
| Cursor | `~/.cursor/skills/` or `~/.agents/skills/` | `.cursor/skills/` or `.agents/skills/` |
| Gemini CLI | `~/.gemini/skills/` or `~/.agents/skills/` | `.gemini/skills/` or `.agents/skills/` |

`~/.agents/skills/` is shared by Codex, Cursor and Gemini CLI, and a project's `.agents/skills/` by all
four non-Claude tools above. These locations were checked in September 2026; tools move fast, so check
your tool's documentation if one doesn't work.

macOS or Linux — set `SKILLS_DIR` to the folder from the table:

```bash
SKILLS_DIR=~/.claude/skills
mkdir -p "$SKILLS_DIR"
cp -R SpecSkills/senior-engineering SpecSkills/spec-driven "$SKILLS_DIR/"
```

Windows (PowerShell):

```powershell
$SkillsDir = "$HOME\.claude\skills"
New-Item -ItemType Directory -Force $SkillsDir | Out-Null
Copy-Item -Recurse -Force SpecSkills\senior-engineering, SpecSkills\spec-driven $SkillsDir
```

### 3. Check it

Start a new session (in VS Code, reload the window) and ask the agent which skills it has. Both
`senior-engineering` and `spec-driven` should be listed.

### Any other tool

1. **It supports Agent Skills** — its documentation mentions "Agent Skills" or `SKILL.md`: copy both
   folders into the skills folder it documents, as in step 2.
2. **It doesn't, but it reads `AGENTS.md`**, as most coding agents do: copy both folders into the
   project, for example under `.agents/skills/`, and add this to the project's `AGENTS.md`:

   ```markdown
   ## Engineering baseline
   Before any task, read .agents/skills/senior-engineering/SKILL.md and follow it. For specs, plans,
   reviews or multi-agent work, also read .agents/skills/spec-driven/SKILL.md. Open the reference
   files they point to only when the task needs them.
   ```

3. **It reads only its own instruction file**: put the same lines there, or one line telling it to read
   `AGENTS.md` first.

A project set up with `spec-driven` also gets `docs/engineering/principles.md`: the rules distilled for
any agent that works on it without the skills installed.

## Using them

- Most tools load a skill on their own when your request matches it. If yours doesn't, ask for it by
  name: "Use the spec-driven skill to start this project."
- **A new project or a major feature: `spec-driven`.** It first asks whether you work with one agent or
  several, proposes the project's size, architecture and practices for you to decide, then works phase
  by phase and stops for your approval at each gate. No code is written until the plan is approved.
- **Everyday work** — designing, coding, testing, reviewing: `senior-engineering` applies throughout.
- **Ideas beyond the task are proposals.** Nothing outside the approved scope is built without your yes.

## Requirements

- A coding agent from the table above, or any that reads `SKILL.md` or `AGENTS.md`.
- Docker, or another container runtime Testcontainers supports, for projects whose integration tests run
  their real dependencies.

## Security

The skills tell the agent never to put secrets, credentials, personal data, internal hostnames or
proprietary code into web searches, MCP servers or any other remote tool. That is an instruction, not an
enforcement, so also block secret files in your tool's permission settings. In Claude Code, for example,
add deny rules such as `"Read(//**/.env)"` and `"Read(~/.ssh/**)"` under `permissions.deny` in
`~/.claude/settings.json`.

## Updating

```bash
cd SpecSkills && git pull
```

Then copy the two folders again, as in step 2.
