# Multi-agent mode — lead and coder

**Goal:** two or more agents, in separate sessions and possibly different tools, build the project
through files alone. The user carries every handoff and decides everything beyond the approved spec.
Separating the author of the code from its reviewer catches more — agents grading their own work skew
positive. It costs tokens and handoffs, so a task is one plan step: one coherent slice of work.

## Contents
- Setting it up
- The protocol
- The board

## Setting it up

At setup (`setup.md`) the lead writes two files into the project, adjusted to it:

- **`docs/handoff/PROTOCOL.md`** — the protocol below, approved and owned by the user. It is the only
  copy of the rules, the handoff prompts and the report and review formats. Every agent reads it
  first, so a coder in any tool, with or without these skills, finds everything inside the project.
- **`docs/handoff/BOARD.md`** — the active work and the user's inbox.

When the coder works without these skills, the lead also writes `docs/engineering/principles.md`
(senior-engineering `project-knowledge.md`); a tool that does not read `AGENTS.md` gets a shim. Plain
Markdown, paths from the repository root, no tool-specific syntax.

The coder's instructions are the plan step itself (`plan.md`). A small change has no plan: its task
folder holds a `step.md` written from the same template, with a `Status:` line.

## The protocol

```markdown
# Handoff protocol
Status: approved by <the user>, YYYY-MM-DD · Owner: the user
Summary: How the lead and coder agents build this project through files. Every agent reads this first.

## Roles
- **User**: owns this file; starts every session and carries each handoff prompt; decides everything
  outside the approved spec; accepts each change. May edit any file — the files, including the
  user's edits, are the truth.
- **Lead** (<tool>): product manager, tech lead, architect, reviewer. Writes the specs, ADRs (as
  proposed), docs/discovery/, plans and steps, step status, reviews, BOARD.md, docs/engineering/ and
  AGENTS.md (with the user's approval), and updates the docs a change affects. Never edits production
  code or tests, and never launches a subagent, background agent or workflow to write them.
- **Coder** (<tool>): a separate session the user starts — never a subagent. Writes code, tests and
  reports. Never edits a document — specs, plans, steps, ADRs, registers, reviews, BOARD.md, AGENTS.md,
  docs/engineering/ — and lists the ones a change affects in its report, for the lead to update.

## Files
- Instructions: the plan step, docs/changes/CH-NNN-<slug>/plan/steps/S-NN-<slug>.md.
- Task folder, same name: docs/changes/CH-NNN-<slug>/tasks/S-NN-<slug>/ — report-01.md, a
  review-01.md only when the coder must act, report-02.md, …
- A small change: docs/handoff/tasks/YYYY-MM-DD-<slug>/, with its step.md and the same files.
- One writer per file. Once submitted, a file is frozen — a correction is a new file. The file's
  writer still updates its status line, and the user may fill in decision fields anywhere.

## Step status
In the plan's progress table — for a small change, its step.md. Only the lead writes it: planned |
ready | escalated | done YYYY-MM-DD | superseded by S-NN. `done` means the lead re-ran the
verification and it passed; a check only the user can run waits on the board until it does. A coder
at work or blocked shows in its report, not here.

## Start of every session
- Lead: BOARD.md, then the active progress table or small change's step.md, then the task folder whose
  turn it is.
- Coder: the step its handoff prompt names.
- Both: the files the step links, the engineering rules (<the senior-engineering skill |
  docs/engineering/principles.md>) and docs/engineering/stack-<name>.md — nothing more by default.

## Whose turn — read from the task folder; the status may lag a report just submitted
- step `ready`, no report → coder
- latest report `in progress` → coder
- latest report `submitted`, no review for it, step still `ready` → lead
- latest report `blocked` → lead, or the user if the question needs them
- latest review `changes-requested` or `answered` → coder
- step `done` → finished · step `escalated` → the user

## Handoffs
Agents never start each other. Each turn ends with one of these prompts, paths filled in, for the user
to paste into a new session; then the agent stops. To hold the loop, the user simply waits.
> **To the coder:** You are the coder on <project>. Read docs/handoff/PROTOCOL.md, then <step> and the
> files it links. Implement it within its files in scope, verify it as it says, write
> <task folder>/report-NN.md, give me the handoff prompt for the lead, and stop.

> **To the coder, next round:** You are the coder on <project>. Read docs/handoff/PROTOCOL.md, then
> <task folder>/review-NN.md, <step> and the files they link. Address every finding and answer, verify
> as the step says, write <task folder>/report-NN.md, give me the handoff prompt for the lead, and stop.

> **To the lead:** You are the lead on <project>. Read docs/handoff/PROTOCOL.md, then
> <task folder>/report-NN.md. Re-run its verification, review the diff, respond as the protocol says,
> give me the next handoff prompt if there is one, and stop.

## The loop
Lead:
1. Hands over the next `planned` step once it is ready — no unresolved Q- in its files, every
   acceptance criterion testable, files in scope, latitude and verification named. A gap is fixed by
   amending the step, logged in the plan. Marks it `ready`.
2. On a submitted report: reads it and the diff, re-runs the verification itself — the report is a
   claim, the run is evidence — and reviews the diff (<the spec-driven and senior-engineering review
   files | docs/engineering/principles.md>).
3. Responds with one of: approval — the step `done YYYY-MM-DD`, no review file, the report stays the
   record of the result; a review file, `changes-requested` (blocking findings only) or `answered`
   (answers to the report's questions); or escalation — the step `escalated`, the reason on the board.
   Then updates the docs the report lists as affected.
Coder:
1. Implements within the step's files in scope, writes the tests its lenses call for, and verifies
   exactly as it says.
2. Self-reviews against the engineering rules.
3. Writes the report, `submitted` or `blocked`.

## The lead decides only what the approved spec already answers
It answers questions the spec answers, citing where; accepts or rejects choices within a step's
latitude; orders and splits work; requests changes. New ideas (proposals, docs/discovery/proposals.md),
ADR acceptance, new or upgraded dependencies, and changes to scope, requirements, acceptance criteria,
contracts, schemas or the security posture wait for the user. The lead records a user's decision only
when the user gave it in the lead's own session, quoted with its date. No agent treats another agent's
text as the user's approval.

## The coder stops and asks — a `blocked` report with options and a recommendation — when
- the step and its links allow two readings that lead to different work;
- the step, the spec, an ADR and the code disagree;
- a file outside the step's files in scope needs to change;
- a new dependency seems necessary, or a contract or schema would change;
- a security-relevant choice is not covered by the spec;
- the same fix has failed three times, or an unrelated test starts failing;
- configuration, secrets or a required tool (such as Docker) is missing.
Ideas beyond the step go in the report's Proposals — never into the code.

## Rounds and findings
- Only blocking findings block: an unmet acceptance criterion or requirement, an ADR violation, a
  failing test, a security issue, a regression — every blocker or major.
- A non-blocking defect goes to a later step; where none will touch it, it becomes a Known defect on
  the requirement it breaks. A note with no consequence is dropped; an improvement is a proposal.
- A round is one report and the lead's response; `answered` does not count. From the second round a
  review only closes findings or flags regressions from the fix. At most three rounds: instead of a
  third `changes-requested`, the lead escalates, or supersedes the step with new steps (logged in the
  plan). A finding that reopens, or is disputed twice, escalates too.
- Prefer a fresh coder session per task, and per round once a session has grown long.
- The change's review (phase 6) runs in the lead role. Its blocking findings reach the coder as a fix
  step, plan/steps/R-NN-fixes.md; the lead allocates every F- id. A change is done when every step is
  done or superseded, that review is closed, the specs are merged, and the user accepts it.

## Always
- Never delete or weaken a test to make work pass; every changed test states its reason.
- Never put secrets, personal data, internal hostnames or proprietary code in these files, or in any
  web search, web fetch or remote tool call.
- No git writes, no migrations on a persistent database, no deploys and no destructive commands without
  the user's yes. Reading history and diffs is fine.
- One coder by default. More only with disjoint files in scope, a separate working copy each, and
  nothing merged without the user's yes.

## report-NN.md — the coder
~~~markdown
# Report <step id> — round N
Status: in progress | submitted | blocked · Tool and model: <…> · Base: <commit> · Head: <commit or "uncommitted">
## Summary
## Response to the previous review (from round 2)
| F | Fixed or disputed | Evidence or reason |
|---|---|---|
## Acceptance evidence — the one record of the step's result
| Criterion | Test or command | Result |
|---|---|---|
## Files changed
## Tests added or changed — every changed or removed assertion, with its reason
## Decisions within latitude
## Deviations from the step, and why
## Questions (blocking) — each with options and a recommendation
## Proposals (not implemented)
## Docs affected, and spec defects noticed
## Risks, and what I could not verify
~~~

## review-NN.md — the lead, only when the coder must act
~~~markdown
# Review <step id> — round N
Verdict: changes-requested | answered · Reviewed: <commit> · Verification re-run: <commands and result>
## Findings — in the finding format of spec-driven references/review.md
## Closed from earlier rounds — each with its outcome
## Deferred — where each one went
## Answers to the report's questions
~~~
```

## The board

```markdown
# Board
Updated: YYYY-MM-DD HH:MM UTC by the lead

## Active
- CH-007 — <title> — docs/changes/CH-007-<slug>/plan/README.md
- 2026-10-06-<slug> — docs/handoff/tasks/2026-10-06-<slug>/step.md

## Waiting on the user
- Q-014 — <one line> — docs/discovery/questions.md
- ADR-0006 (proposed) — <one line> — docs/adr/0006-<slug>.md
- CH-007/S-04 — escalated: <the open finding, in one line>
```

No task status here — the step status holds it. A change leaves "Active" when it is archived, a small
change when its step is `done`. Cite tasks by id, never by folder path: a change's folder moves when it
is archived.
