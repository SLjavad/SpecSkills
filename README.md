# SpecSkills

Three agent skills for spec-first, senior-level software engineering. They work with Claude Code and
with any coding agent that supports the open [Agent Skills](https://github.com/agentskills/agentskills)
format (`SKILL.md` folders), and they fall back to plain project files for tools that don't.

## What's inside

| Skill | What it does |
|---|---|
| `senior-engineering` | The baseline for any code work: ask instead of guessing; design with the project's own rules plus SOLID, DRY and KISS/YAGNI, and no abstraction without a present need; rich domain entities; security as part of correctness; no confidential data in remote tool calls; tests that challenge business rules, the technical solution, performance and security, with every external dependency run for real through Testcontainers; code review; ADRs. |
| `spec-driven` | Runs a project spec-first as small, linked files: discovery, product spec, numbered, testable requirements with a traceability matrix, a tech spec with ADRs and a stack playbook, a stepwise plan, and review. Size, architecture and practices are decided with you at setup; later features are change folders merged into living specs; one agent, or a lead and a coder working through files. |
| `work-orchestrator` | Hands light, read-heavy work — builds and test runs, code searches, long logs, mechanical doc checks — to cheaper, faster helper models, so the session's main model spends its tokens on judgment. Helpers return facts only; implementation and review are never delegated, and no helper edits files. |

`spec-driven` and `work-orchestrator` build on `senior-engineering`, and link to it as
`../senior-engineering/` — the three always sit side by side in one folder. The installer takes care
of that.

## Installation

One installer sets up everything in this repository, or only the skills you name, on Windows, macOS
and Linux:

- **the three skills**, for Claude Code and for every other agent tool it finds on the machine;
- **for Claude Code**, the `work-orchestrator` extras: four helper agents, a guard hook that keeps every
  subagent off the top-tier model, the settings that make both work, and an exemption in your
  `CLAUDE.md` if it asks you before every subagent.

### Before you start

| You need | Why |
|---|---|
| Git | to get the repository and to update it later — or download it as a ZIP |
| **Windows:** nothing else | the installer uses Windows PowerShell, built into Windows 10 and 11 |
| **macOS / Linux:** bash, and `python3` | bash runs the installer; Python edits `settings.json` safely. Without Python, the installer does every other step and prints the settings to add by hand |
| Docker, or another runtime Testcontainers supports | not for installing — for projects whose integration tests run their real dependencies |

You don't need to close Claude Code first: the installer only writes files, and Claude Code picks up
the changes in the next session you start.

### Step 1 — Get the repository

```bash
git clone https://github.com/SLjavad/SpecSkills.git
```

If you use only Claude Code, you can clone it straight into its skills folder instead. The skills are
then live where Claude Code reads them, and updating is a `git pull`:

```bash
git clone https://github.com/SLjavad/SpecSkills.git ~/.claude/skills
```

That needs `~/.claude/skills` to be empty or absent. Other skills you install later can live in the
same folder; Git ignores them.

### Step 2 — See what it will do

Run the installer with `--dry-run` first. It prints every file it would add, update or remove, and
writes nothing.

**Windows** — in PowerShell, from the repository folder:

```powershell
.\install.cmd --dry-run
```

**macOS / Linux** — in a terminal, from the repository folder:

```bash
./install.sh --dry-run
```

### Step 3 — Install

The same command without `--dry-run`. It installs all three skills; to install only some, see
[Choosing skills](#choosing-skills).

**Windows** — PowerShell or Command Prompt, or double-click `install.cmd` in Explorer:

```powershell
.\install.cmd
```

**macOS / Linux:**

```bash
./install.sh
```

`install.cmd` runs `install.ps1` without changing your PowerShell execution policy, which is why it is
the easiest way on Windows. From Git Bash on Windows, `./install.sh` works too — it hands over to the
PowerShell installer.

Then **start a new Claude Code session**: it loads helpers, hooks and settings when a session starts.

### What the installer does

| Step | What happens | Where |
|---|---|---|
| Skills | Copies the skill folders — all three, or the ones you name — and removes files an update deleted from them. If the repository *is* the folder — a clone into `~/.claude/skills` — it skips this; `git pull` keeps them current. | `~/.claude/skills/`; also `~/.agents/skills/` if Codex, Cursor or Gemini CLI is installed, and `~/.copilot/skills/` if GitHub Copilot is |
| Helpers — with `work-orchestrator` only, as are the three steps below | Installs `runner`, `scout`, `log-digest` and `doc-check`, each pinned to Haiku | `~/.claude/agents/` |
| Guard | Installs the guard that refuses any subagent not on its allowlist, and any launch that asks for an Opus or Fable model — as PowerShell on Windows, bash elsewhere — with the allowlist beside it | `~/.claude/hooks/` |
| Settings | Removes `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` (it stops helpers using their own model); sets `CLAUDE_CODE_SUBAGENT_MODEL` to Sonnet if it is unset or a top-tier model; registers the guard next to your existing hooks. Everything else in the file stays as it was. | `~/.claude/settings.json` |
| Instructions | If your `CLAUDE.md` has a rule to ask before launching subagents, adds one paragraph exempting the four helpers. Without such a rule, it changes nothing. | `~/.claude/CLAUDE.md` |

### Safety

- **Every file it replaces or removes is backed up first**, into one folder per run:
  `~/.claude/backups/spec-skills/<date-time>/`. To undo a change, copy the file back from there.
- **`--dry-run` writes nothing** — use it whenever you are unsure.
- **Running it again is safe.** It compares every file and changes only what differs; when nothing
  does, it says "Already up to date".
- **It stops before changing anything** if `settings.json` is not valid JSON.
- **It touches only what it installs.** Other skills, agents, hooks and settings keep their place and
  content; a settings entry is added or updated, never the whole file replaced; line endings and
  encoding are kept.

### Options

| Option | Effect |
|---|---|
| *skill names* | Install or uninstall only these skills — see below. None named means all of them. |
| `--dry-run` | Show the plan; write nothing |
| `--uninstall` | Remove the skills, and with `work-orchestrator` its helpers, the guard and its settings entry, and the `CLAUDE.md` exemption — with backups. Your other skills and settings stay. |
| `--help` | Show the options |

In PowerShell, `-DryRun` and `-Uninstall` work as well. To install into a Claude Code folder other than
`~/.claude`, set `CLAUDE_CONFIG_DIR` before running it.

### Choosing skills

Name the skills after the options, separated by spaces or commas:

```bash
./install.sh spec-driven
./install.sh --uninstall work-orchestrator
```

On Windows the same goes after `.\install.cmd`.

- **Installing** puts in only the named skills and leaves the others as they are. A skill that another
  one links into comes along: `spec-driven` brings `senior-engineering`, and the installer says so.
  The helpers, the guard, the settings and the `CLAUDE.md` exemption come only with `work-orchestrator`.
- **Uninstalling** removes the named skills — or, with no names, every one of the three that is
  installed — from every tool folder, backing each file up first. It refuses, and changes nothing,
  when a skill you keep links into one you are removing, such as `senior-engineering` while
  `spec-driven` stays.
- **A skill folder belongs to the installer.** Installing makes it match the repository and uninstalling
  removes it, files you added included — both back them up first. A skill folder that is a link, and a
  tool folder that *is* this repository, are left alone.
- **An unknown name stops it** before anything changes, listing the skills it knows.

### Check it

In a new Claude Code session, ask which skills it has: `senior-engineering`, `spec-driven` and
`work-orchestrator` should be listed. Then check the helpers:

```text
Start the runner helper with `node --version` or `git --version`, and have it report the model it
runs on. Then start a subagent named "no-such-agent" and quote the reason the guard refuses it.
```

The runner should report Haiku, and the guard should refuse the unknown agent.

### Updating

```bash
git -C SpecSkills pull
```

Then run the installer again (Step 3). With a clone in `~/.claude/skills`, the pull already updates the
skills; the installer brings the helpers, the guard and the settings up to date.

### Installing by hand, or in another tool

The installer covers the tools in this table. For a tool it does not know, copy the three skill folders
into its skills folder yourself:

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

- **A tool that supports Agent Skills** — its documentation mentions "Agent Skills" or `SKILL.md`:
  copy the folders into the skills folder it documents.
- **A tool that doesn't, but reads `AGENTS.md`**, as most coding agents do: copy the folders into the
  project, for example under `.agents/skills/`, and add this to the project's `AGENTS.md`:

  ```markdown
  ## Engineering baseline
  Before any task, read .agents/skills/senior-engineering/SKILL.md and follow it. For specs, plans,
  reviews or multi-agent work, also read .agents/skills/spec-driven/SKILL.md; before running builds
  or tests, searching code or reading long logs, read .agents/skills/work-orchestrator/SKILL.md. Open
  the reference files they point to only when the task needs them.
  ```

- **A tool that reads only its own instruction file**: put the same lines there, or one line telling it
  to read `AGENTS.md` first.

The Claude Code extras — helpers, guard and settings — by hand: `work-orchestrator/references/claude-code.md`.

A project set up with `spec-driven` also gets `docs/engineering/principles.md`: the rules distilled for
any agent that works on it without the skills installed.

## Using them

- Most tools load a skill on their own when your request matches it. If yours doesn't, ask for it by
  name: "Use the spec-driven skill to start this project."
- **A new project or a major feature: `spec-driven`.** It first asks whether you work with one agent or
  several, proposes the project's size, architecture and practices for you to decide, then works phase
  by phase and stops for your approval at each gate. A small project takes the small track: the same
  phases in three spec files and two approval stops. No code is written until the plan is approved.
- **Everyday work** — designing, coding, testing, reviewing: `senior-engineering` applies throughout.
- **Long runs, big searches, long logs: `work-orchestrator`.** The agent hands them to a cheap helper and
  reads back only the facts. You don't call it; it applies when a task fits.
- **Ideas beyond the task are proposals.** Nothing outside the approved scope is built without your yes.

## Security

The skills tell the agent never to put secrets, credentials, personal data, internal hostnames or
proprietary code into web searches, MCP servers or any other remote tool. That is an instruction, not an
enforcement, so also block secret files in your tool's permission settings. In Claude Code, for example,
add deny rules such as `"Read(//**/.env)"` and `"Read(~/.ssh/**)"` under `permissions.deny` in
`~/.claude/settings.json`.

The guard hook is an enforcement: Claude Code runs it before every subagent launch, and it refuses any
launch that is not on its allowlist or asks for a top-tier model.
