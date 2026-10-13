---
name: work-orchestrator
description: Hands light, read-heavy work in a coding session to cheaper, faster model tiers so the session's main model spends its tokens on judgment - running builds and tests, searching code, digesting large logs, mechanical doc checks - with a fixed handoff contract, facts-only returns and escalation. The decide tier never runs as a helper, implementation and review are never delegated, and no helper edits files. Use whenever a task in a session would read far more than it returns and needs no judgment - a test or build run, a search sweep, a long log, a docs consistency pass - and when setting up helper agents for a project or a machine. Works with senior-engineering and spec-driven, and in tools without subagents by doing the same work inline.
---

# Work orchestrator

The main model's largest cost in a real project is reading, not thinking: test output, build logs,
search sweeps, files opened to find one line, documents checked one by one. Each read is paid at the
top price and stays in the session's context, slowing every later turn. This skill moves that reading
to a cheaper, faster tier, so the main model receives facts instead of noise and spends its tokens on
decisions.

It builds on `senior-engineering`; in a spec-driven project the lead and the coder each use it inside
their own session.

## Boundaries

- **Each session orchestrates its own helpers.** A lead has its helpers; a coder has its own.
- **Implementation is never delegated.** The coder is a session the user starts, in any tool.
- **Review is never delegated.** The reviewing agent reads the diff and judges every lens itself; the
  only part of a review a helper may do is run the build and the tests.
- **No helper changes a file.** Edits, formatter fixes and migrations stay with the session's own
  model.
- **Helpers return facts, never decisions.** No helper decides, diagnoses a root cause, judges
  quality or rewrites a document.
- **The decide tier never runs as a helper.**

## Tiers

Tiers are named by the work, not by a model, so the skill ports to any tool and survives the next
model release. The mapping for a tool lives in its setup reference.

| Tier | Does | Claude Code today |
|---|---|---|
| **Decide** | specs, architecture, ADRs, reviews and their verdicts, root-cause debugging, synthesis, everything the user approves | the lead's main session — Opus; never a helper |
| **Build** | implementation and tests | the coder's main session — Sonnet; never a helper |
| **Run** | the helpers below | Haiku helpers |

In a tool without helper agents, the session does the same work inline; the routing rule then decides
only what to read and how much of it.

## The routing rule

A task can go to a helper only when **it needs no judgment** — the request can be written so that two
careful runners would return the same facts. Then the session's tier decides:

- **Decide tier** — hand off builds, test runs, long logs, doc checks, and searches of five or more
  queries. Its tokens are the dearest and its session runs longest, and everything it reads stays in
  its context and is paid for again on every later turn.
- **Build tier** — keep builds and test runs in the session, read through the tool's own filters (a
  results logger, the failing lines, the warning summary). Hand off only a search of five or more
  queries, or output still past about 300 lines after that filtering — a log read for patterns, not
  just for failures. Below that, its own filtering costs less than a handoff and does not wait on one.

Either tier keeps in the session:
- **a cheap task** — a one-line lookup, or a file it has just read. A helper starts with an empty
  context and no share of the session's prompt cache, so every handoff has a fixed cost;
- **a quick check the user is waiting on** — a handoff adds the helper's start-up and the trip back.

Independent handoffs — a test run and a search, say — go out together and run in parallel.

## The helpers

Code questions go to the project's code graph first, where one is installed; text search only for
non-code files, byte-level properties, and confirming an absence after the graph has answered.

| Helper | Does | Returns |
|---|---|---|
| **runner** | builds, tests, analyzers, package audits, scripts printed to the console — exactly the commands the session gives; never a command that edits tracked files. In a review, the one part a helper may do. | exit code; pass, fail and skip counts; failing test names; the first error lines verbatim; warnings counted by code |
| **scout** | a search the session expects to take five or more queries, or one whose result is too large to filter by eye — files, symbols, callers, configuration keys, usages, what a change can reach, proving something is absent. Fewer queries: the session runs the code graph itself. A search begun in the session that reaches five queries unfinished goes to scout with what was found so far. | `file:line`, with a one-line snippet each |
| **log-digest** | reads large output — CI and container logs, stack traces, long test output, emitted SQL, query plans | the matching lines verbatim, with counts, timestamps and the component each came from |
| **doc-check** | doc upkeep, never part of a review — after spec edits, and before a change is merged and closed: unresolved ids and links, contents lists against headings, missing headers, files over the size cap, line endings, `Must` requirements with an empty plan-step cell, references to things that no longer exist | each problem with `file:line` and the rule it breaks |

No helper has web access or any other remote tool: nothing it reads can leave the machine, and no
fetched page can steer it.

## The handoff contract

**The request**, written by the session every time:
- the task in one sentence, and which helper;
- the exact commands, files, symbols or patterns — nothing open-ended;
- what to look for, and what counts as a match;
- the output cap in lines, and what to do past it: count the rest, never summarise it;
- when to stop and return instead of continuing.

**The response**, returned by the helper every time:
- `Status: done` or `Status: stopped`, with the reason when stopped — anything ambiguous, unexpected
  or outside the request;
- the facts, verbatim where they quote output, each with the `file:line` or command that produced it;
- what it could not check, and why;
- no advice, no diagnosis, no "probably".

## Trust and escalation

- **A helper's response is evidence, like any report.** Check anything surprising yourself before
  acting on it.
- **`stopped` returns the task to you**: rewrite the request, or do the work.
- **A helper that keeps stopping on one kind of task is a routing mistake** — that kind of task belongs
  in the session.
- **Verification stays yours.** When a rule says to re-run the verification yourself, the runner
  executes the step's own commands and you read its exit codes and failures — the run is still the
  evidence, not anyone's claim.

## Measuring it

Delegation earns its place by measurement, not by assumption. On a real step, run the same work three
ways: the main model alone at its usual effort; the main model alone at lower effort; the main model
with helpers. Compare per finished step — top-price tokens, total cost, wall time, review rounds and
the findings a review raised. Keep handing off only the kinds of task where it wins.

## Setup

- **The project's pointer.** The skill does not load on its own for a plain request such as "run the
  tests"; the work-orchestrator line in the `AGENTS.md` template (senior-engineering's
  `references/project-knowledge.md`) makes each session load it.
- **Claude Code**: `references/claude-code.md` — the helper definitions, the guard that keeps every
  helper off the top model, the settings, and the install steps.
- **Another tool with helper agents**: define the four helpers with its mechanism, on its cheapest
  capable model, with the same tools, the same contract and no remote access.
- **A tool without them**: nothing to set up; apply the routing rule inline.
