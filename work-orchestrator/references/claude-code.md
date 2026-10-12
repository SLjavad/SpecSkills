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

1. **The helpers.** Copy `claude-code/agents/*.md` from this skill into `~/.claude/agents/`. Each one
   names `model: haiku` and `effort: high`, its tool allowlist, and its part of the handoff contract.
   The scout lists the `codebase-memory-mcp` server's tools. On a machine without that server it falls
   back to Read, Grep and Glob and says so in its answer; if Claude Code reports the missing tool names,
   remove them from its `tools` line.
2. **The guard.** Copy `claude-code/hooks/agent-guard.js` into `~/.claude/hooks/`. It needs Node, which
   Claude Code already requires.
3. **The settings**, in `~/.claude/settings.json` — merged into what is there, never replacing it:

   ```json
   {
     "env": {
       "CLAUDE_CODE_SUBAGENT_MODEL": "claude-sonnet-5-5"
     },
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Agent|Task",
           "hooks": [
             { "type": "command", "command": "node ~/.claude/hooks/agent-guard.js", "timeout": 5 }
           ]
         }
       ]
     }
   }
   ```

   Remove `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` if it is set. Keep `CLAUDE_CODE_SUBAGENT_MODEL` on a
   non-top-tier model: it is the model of every subagent that names none.
4. **Asking before subagents.** If your instructions require asking before any subagent is launched,
   exempt these four helpers — they run on their declared model and effort with their output caps —
   and keep the rule for every other agent and for any change to these definitions.
5. Start a new session; Claude Code loads agents and settings at session start.

## The guard

`agent-guard.js` runs before every subagent launch and denies it, with a reason the agent can read,
when:

- the launch names a top-tier model — any model whose name contains `opus`, `fable` or `mythos`; or
- the subagent is not on its allowlist: the four helpers, `general-purpose`, `claude`,
  `claude-code-guide` and `statusline-setup`.

Every allowed subagent then runs on a non-top-tier model: the helpers on Haiku by definition, the rest
on `CLAUDE_CODE_SUBAGENT_MODEL`, or on Haiku and Sonnet as Claude Code ships them. A new subagent is
allowed by adding its name to the list — after checking that its definition names a model that is not
top tier and not `inherit`. If the guard cannot read its input, it blocks the launch.

## Explore and Plan

They stay installed, but until one of these routes is confirmed the guard refuses them, because they
would run on the top tier in a lead session. The skill points agents to `scout` for searching, and Plan
starts only in plan mode.

1. **Same-name redefinition** — a user-defined `Explore` with `model: haiku` and `Plan` with
   `model: sonnet` in `~/.claude/agents/`. If Claude Code lets a user definition replace a built-in of
   the same name, add both names to the guard's allowlist.
2. **A model passed at launch** — on a version whose subagent tool takes a model, the guard could set
   one instead of refusing.
3. **Neither** — they stay refused, or are allowed as a stated exception that may run on the top tier.

## Checking it works

In a new session after installing:
- start `runner` with a harmless command (`dotnet --version`, `node --version`) and ask it to report its
  model — it should say Haiku;
- start an unknown agent name — the guard should refuse it with its reason;
- start `Explore` — refused until a route above is confirmed; once one is, it should report a model
  that is not top tier;
- fork the session, if your version offers forks, and check whether the guard sees it.
