# Claude Code setup

How the skill's helpers run in Claude Code: four helper definitions on Haiku, a guard that keeps every
subagent off the top tier, and the settings that let both work. Checked against the Claude Code
subagent documentation on 2026-10-12, for version 2.1.284.

## Contents
- How Claude Code picks a subagent's model
- Install
- The guard
- Explore and Plan
- Checking it works

## How Claude Code picks a subagent's model

In this order, first match wins:

1. a model passed when the subagent is started (newer versions only; 2.1.284's subagent tool has no
   model parameter);
2. the `model` field of the subagent's definition — `inherit` means the main session's model;
3. the `CLAUDE_CODE_SUBAGENT_MODEL` environment variable;
4. the main session's model.

`CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides all of it: every subagent then runs on
`CLAUDE_CODE_SUBAGENT_MODEL`, and the `model` field of every definition is ignored. The helpers cannot
run on Haiku while it is set.

The built-in **Explore** and **Plan** subagents run on the main session's model; **general-purpose**
and the catch-all **claude** agent fall back to `CLAUDE_CODE_SUBAGENT_MODEL`.

## Install

The repository's installer does all of it — see the README's "Installation": `install.cmd` (or
`install.ps1`) on Windows, `install.sh` on macOS and Linux, with `--dry-run` and `--uninstall`. It
needs no Node. What it does for this skill, which is also how to do it by hand:

1. **The helpers.** `claude-code/agents/*.md` into `~/.claude/agents/`. Each one names `model: haiku`
   and `effort: high`, its tool allowlist, and its part of the handoff contract. The scout lists the
   `codebase-memory-mcp` server's tools; on a machine without that server it falls back to Read, Grep
   and Glob and says so in its answer.
2. **The guard.** From `claude-code/hooks/` into `~/.claude/hooks/`: `agent-guard.ps1` on Windows,
   `agent-guard.sh` elsewhere — the same rules in each — and `agent-guard.allow`, the allowlist: the
   built-in subagents listed in this skill's copy, plus the helpers' names.
3. **The settings**, merged into `~/.claude/settings.json`: remove `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`;
   keep `CLAUDE_CODE_SUBAGENT_MODEL` on a model that is not top tier, `claude-sonnet-5-5` by default —
   it is the model of every subagent that names none; and register the guard, as `hooks.list`
   describes, next to any existing hooks:

   ```json
   { "matcher": "Agent|Task",
     "hooks": [ { "type": "command", "command": "bash \"/home/you/.claude/hooks/agent-guard.sh\"", "timeout": 10 } ] }
   ```

   On Windows the command is
   `powershell -NoProfile -ExecutionPolicy Bypass -File "C:/Users/you/.claude/hooks/agent-guard.ps1"`.
4. **Asking before subagents.** If your instructions require asking before any subagent is launched,
   exempt these four helpers — they run on their declared model and effort with their output caps —
   and keep the rule for every other agent and for any change to these definitions.
5. Start a new session; Claude Code loads agents, hooks and settings at session start.

## The guard

The guard runs before every subagent launch and denies it, with a reason the agent can read, when:

- the launch names a top-tier model — any model whose name contains `opus`, `fable` or `mythos`; or
- the subagent is not in `agent-guard.allow`: by default the four helpers, `general-purpose`, `claude`,
  `claude-code-guide` and `statusline-setup`.

Every allowed subagent then runs on a non-top-tier model: the helpers on Haiku by definition, the rest
on `CLAUDE_CODE_SUBAGENT_MODEL`, or on Haiku and Sonnet as Claude Code ships them. A new subagent is
allowed by adding its name to the allowlist — after checking that its definition names a model that is
not top tier and not `inherit`. If the guard cannot read its input or its allowlist, it blocks the
launch.

## Explore and Plan

They stay installed as Claude Code ships them, and the guard refuses them by decision, because they run
on the main session's model — the top tier in a lead session. This skill does not replace, re-model or
allowlist them; `scout` covers searching, and Plan starts only in plan mode.

## Checking it works

In a new session after installing:
- start `runner` with a harmless command (`git --version`) and ask it to report its model — it should
  say Haiku;
- start an unknown agent name — the guard should refuse it with its reason;
- start `Explore` — the guard should refuse it;
- fork the session, if your version offers forks, and check whether the guard sees it.
