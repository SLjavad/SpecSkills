# SpecSkills

**Two agent skills that make your coding agent work like a senior engineer — and take bigger work
spec-first.**

![Format: Agent Skills](https://img.shields.io/badge/format-Agent%20Skills-blue)
![Platforms](https://img.shields.io/badge/install-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

They run in Claude Code, OpenAI Codex, GitHub Copilot, Cursor and Gemini CLI — any tool that reads the
open [Agent Skills](https://github.com/agentskills/agentskills) format (`SKILL.md` folders) — and fall
back to plain project files for tools that don't.

## Quick start

```bash
git clone https://github.com/SLjavad/SpecSkills.git
cd SpecSkills
```

| Windows | macOS / Linux |
|---|---|
| `.\install.cmd` | `./install.sh` |

Start a new session in your agent tool, and the skills are there. Add `--dry-run` to see every file the
installer would touch, without writing anything.

## What you get

### `senior-engineering` — the baseline for every code task

- **Asks instead of guessing**, and brings ideas as proposals — nothing outside the task is built
  without your yes.
- **Designs simply**: the project's own rules, then SOLID, DRY and KISS/YAGNI; rich domain entities;
  no abstraction without a present need.
- **Follows your architecture** — Clean, vertical slices, modular monolith, microservices,
  event-driven, DDD — and uses patterns only where they earn their place.
- **Treats security as correctness**, and keeps secrets and confidential data out of web searches and
  remote tools.
- **Tests what the code should do, then tries to break it** — business rules, the technical solution,
  performance and security, with real dependencies through Testcontainers and end-to-end tests for the
  critical journeys.
- **Has a procedure** for debugging, for performance investigation and for safe refactoring, plus code
  review and ADRs.

### `spec-driven` — spec first, for a new project or a major feature

- **One phase at a time**: discovery of every gray area → product spec → numbered, testable
  requirements with a traceability matrix → tech spec with ADRs and a stack playbook → a stepwise
  plan → review.
- **You decide** the size, architecture and practices at setup, and approve each phase at its gate. No
  code is written before the plan — or the small track's page — is approved.
- **A small track** for a script or a one-job tool: one page, one approval.
- **Living specs**: a later feature is a change folder, merged into the specs when you accept it.
- **One agent, or a lead and a coder** that work together through files.

`spec-driven` builds on `senior-engineering` and links to it as `../senior-engineering/`, so the two
sit side by side — the installer takes care of that.

## Using them

| When you are… | What happens |
|---|---|
| Designing, coding, testing, debugging, refactoring, speeding up or reviewing code | `senior-engineering` applies throughout |
| Starting a new project or a major feature | `spec-driven` asks whether you work with one agent or several, proposes the size, architecture and practices for you to decide, then stops for your approval at every gate |
| Writing a script or a one-job tool | `spec-driven` takes the small track: one agent, one page, one approval |

Most tools load a skill by themselves when your request matches it. If yours doesn't, ask by name:
*"Use the spec-driven skill to start this project."*

## Installation

**You need** Git, or the repository as a ZIP; on macOS and Linux, bash — Windows needs nothing else.
Projects whose integration tests run their real dependencies also need Docker, or another runtime
Testcontainers supports.

1. **Get it** — `git clone https://github.com/SLjavad/SpecSkills.git`
2. **Preview** — `.\install.cmd --dry-run` on Windows, `./install.sh --dry-run` elsewhere. It lists
   every file it would add, update or remove, and writes nothing.
3. **Install** — the same command without `--dry-run`. On Windows you can also double-click
   `install.cmd`.
4. **Check** — start a new session and ask which skills it has: `senior-engineering` and `spec-driven`
   should be listed.

There is no need to close your agent tool first; the skills load in the next session.
**To update**, run `git -C SpecSkills pull`, then the installer again.

<details>
<summary><b>Where it installs, and why it is safe to run again</b></summary>

- **Where** — `~/.claude/skills/`; also `~/.agents/skills/` when Codex, Cursor or Gemini CLI is
  installed, and `~/.copilot/skills/` when GitHub Copilot is. Set `CLAUDE_CONFIG_DIR` to install into
  another Claude Code folder.
- **Backed up** — every file it replaces or removes is first copied to
  `~/.claude/backups/spec-skills/<date-time>/`. To undo a change, copy the file back.
- **Repeatable** — it changes only what differs, and says "Already up to date" when nothing does.
- **Contained** — it touches only the skill folders it installs; your other skills and settings keep
  their place. Those skill folders belong to the installer: installing makes each one match the
  repository and uninstalling removes it — files you added included, backed up first. A skill folder
  that is a link, and a tool folder that *is* this repository, are left alone.
- **Windows** — `install.cmd` runs `install.ps1` without changing your execution policy. From Git Bash,
  `./install.sh` hands over to the PowerShell installer.

</details>

<details>
<summary><b>Options — dry run, uninstall, one skill only</b></summary>

| Option | Effect |
|---|---|
| *skill names* | Only these skills, separated by spaces or commas. None named means all of them. |
| `--dry-run` | Show the plan; write nothing |
| `--uninstall` | Remove the skills, with backups; your other skills stay |
| `--help` | Show the options |

In PowerShell, `-DryRun` and `-Uninstall` work as well. On Windows the same arguments go after
`.\install.cmd`:

```bash
./install.sh spec-driven
./install.sh --uninstall spec-driven
```

- **Installing named skills** puts in only those, plus any skill they link into — `spec-driven` brings
  `senior-engineering`, and the installer says so — and leaves the others as they are.
- **Uninstalling** removes the named skills — or, with none named, both — from every tool folder. It
  refuses, and changes nothing, when a skill you keep links into one you are removing, such as
  `senior-engineering` while `spec-driven` stays.
- **An unknown name** stops it before anything changes, listing the skills it knows.

</details>

<details>
<summary><b>Claude Code only — clone straight into its skills folder</b></summary>

```bash
git clone https://github.com/SLjavad/SpecSkills.git ~/.claude/skills
```

The skills are then live where Claude Code reads them, and updating is a `git pull`. This needs
`~/.claude/skills` to be empty or absent; skills you add there later are ignored by Git. The installer
skips that folder and still updates every other tool's.

</details>

<details>
<summary><b>Installing by hand, or in another tool</b></summary>

Copy the two skill folders into the tool's skills folder:

| Tool | For you, in every project | For one project (commit it to share) |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| OpenAI Codex | `~/.agents/skills/` | `.agents/skills/` |
| GitHub Copilot (VS Code, CLI, cloud agent) | `~/.copilot/skills/` | `.github/skills/` or `.agents/skills/` |
| Cursor | `~/.cursor/skills/` or `~/.agents/skills/` | `.cursor/skills/` or `.agents/skills/` |
| Gemini CLI | `~/.gemini/skills/` or `~/.agents/skills/` | `.gemini/skills/` or `.agents/skills/` |

`~/.agents/skills/` is shared by Codex, Cursor and Gemini CLI, and a project's `.agents/skills/` by all
four non-Claude tools. These locations were checked in September 2026; tools move fast, so check your
tool's documentation if one doesn't work.

- **A tool that supports Agent Skills** — its documentation mentions "Agent Skills" or `SKILL.md`:
  copy the folders where it says.
- **A tool that doesn't, but reads `AGENTS.md`**, as most coding agents do: copy the folders into the
  project, for example under `.agents/skills/`, and add this to the project's `AGENTS.md`:

  ```markdown
  ## Engineering baseline
  Before any task, read .agents/skills/senior-engineering/SKILL.md and follow it. For specs, plans,
  reviews or multi-agent work, also read .agents/skills/spec-driven/SKILL.md. Open the reference
  files they point to only when the task needs them.
  ```

- **A tool that reads only its own instruction file**: put the same lines there, or one line telling it
  to read `AGENTS.md` first.

A project set up with `spec-driven` also gets `docs/engineering/principles.md` — the rules distilled for
any agent that works on it without the skills. A small-track project does not; one agent with the
skills works on it.

</details>

## Security

The skills tell the agent never to put secrets, credentials, personal data, internal hostnames or
proprietary code into web searches, MCP servers or any other remote tool. That is an instruction, not
enforcement — so also block secret files in your tool's permissions. In Claude Code, for example, add
deny rules such as `"Read(//**/.env)"` and `"Read(~/.ssh/**)"` under `permissions.deny` in
`~/.claude/settings.json`.

## License

MIT — see [LICENSE](LICENSE).
