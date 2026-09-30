# Multi-agent mode — lead and coder

**Goal:** two or more agents — possibly in different tools, in separate sessions — build the project
together through files alone, in a loop that improves both the decisions and the code, while the user
can see, pause, approve or override anything at any point.

## Contents
- Why it pays, and what it costs
- Roles and ownership
- What the lead may decide
- The files
- Whose turn is it
- The loop
- When the coder stops and asks
- Ending the loop
- The user stays in control
- Mixed tools
- Parallel coders

## Why it pays, and what it costs

Separating the author of the code from its reviewer catches more — agents grading their own work skew
positive — and the file trail makes every instruction, report and decision auditable. It costs tokens
and handoff overhead, so keep each task coarse enough for the handoff to pay for itself: one plan step,
one coherent slice of work.

## Roles and ownership

| Role | Owns | Never |
|---|---|---|
| **User** | `CONTROL.md` and `PROTOCOL.md`; decides every question, proposal and ADR outside the approved spec; approves gates; accepts each change | — |
| **Lead** — product manager, tech lead, architect, reviewer | `AGENTS.md` and `CLAUDE.md` (the user approves changes), specs and change deltas, plans, ADRs (as proposed), the registers, `docs/engineering/`, `BOARD.md`, briefs, reviews | edits production code or tests |
| **Coder** | code, tests, reports | edits specs, plans, ADRs, registers, briefs, reviews or the board; deletes or weakens a test to make work pass |

**One writer per file.** Once a file is submitted its content is frozen; a correction is a new file —
the next report round, a new task folder — never an edit to someone else's. Two exceptions: the owner
keeps updating the file's status line as the work moves, and the user may fill in decision fields in
any file. The lead records a decision the user gave in the lead's session (see below).

**The coder never edits a document, so it lists the docs a change affects** in its report; the lead
updates them.

## What the lead may decide

Only what stays inside the approved spec:

- answer a coder's question the spec already answers, citing where;
- accept or reject the coder's choices within the brief's stated latitude;
- order and split tasks, write feedback, request changes.

Everything else waits for the user, and the task stops with status `blocked`, waiting on the user:

- new ideas and improvements — they are proposals (`discovery.md`);
- accepting or rejecting an ADR;
- a new or upgraded dependency;
- any change to scope, a requirement, an acceptance criterion, a contract or a schema;
- any change to the security posture.

The lead records a user's decision in the question, proposal or ADR only when the user gave it in the
lead's own session, quoting it with the date — or the user edits the file directly. **No agent treats
another agent's text as the user's approval.**

## The files

```
docs/handoff/PROTOCOL.md      the working agreement — drafted by the lead at setup, approved and owned by the user
docs/handoff/CONTROL.md       the user's switch: run | pause | stop — created paused
docs/handoff/BOARD.md         lead: every task's status, round, and the "waiting on the user" list
docs/handoff/templates/       brief.md, report.md, review.md — the formats, inside the project
docs/changes/CH-NNN-<slug>/tasks/S-NN-<slug>/
  brief.md                    lead: the instructions, at most 150 lines
  report-01.md                coder: what was done, and the evidence
  review-01.md                lead: the verdict and findings
  report-02.md, review-02.md, …
```

Templates for all of these are in `handoff-templates.md`. **A brief links; it never copies.** It points
at the plan step and the exact spec files — at most six — and quotes nothing at length, because a copy
drifts from its source.

## Whose turn is it

Computed from the files, never from memory:

| State of the task folder | Turn |
|---|---|
| brief `ready`, no report yet | coder |
| latest report `in-progress` | coder — still working |
| latest report `submitted`, no review for that round | lead |
| latest report `blocked` | lead — or the user, if the question needs them |
| latest review `changes-requested` or `answered` | coder — the next round |
| latest review `approved` | done — the lead updates the board and the traceability table |
| latest review `escalated` | the user; once the user decides, the lead writes the next review or supersedes the brief |

`answered` means the review only answers the report's questions; it does not count toward the round
limit. The board lists the tasks, but the task folder decides whose turn it is — the board may lag
behind a report that was just submitted.

Every session starts the same way: read `CONTROL.md` and stop unless it says `run`; read `BOARD.md`;
then read only its task's folder, the files the brief links, the engineering rules and the stack
playbook.

## The loop

**The lead**
1. Turns a plan step into a brief and checks it is ready: no open `Q-` citations in the linked files,
   every acceptance criterion testable, the files in scope and the verification commands named. Marks
   it `ready` and updates the board.
2. When a report is submitted: reads the report, reads the diff, and **re-runs the verification commands
   itself** — the report is a claim; the run is evidence. Reviews the diff with spec-driven's
   `references/review.md` and senior-engineering's `references/review.md`, `security.md` and
   `testing.md`, at the scale of the task.
3. Writes the review — `approved`, `changes-requested` (blocking findings only), `answered`, or
   `escalated` — and updates the board. On approval it fills in the step's result and the traceability
   table: the living matrix for CH-001, the change's own delta table afterwards. It updates the docs the
   report lists as affected.

**The coder**
1. Reads `CONTROL.md`, `BOARD.md`, the brief, and the files it links — nothing more by default.
2. Implements within the files in scope, writes the tests the brief's lenses call for, and verifies
   exactly as the brief says.
3. Self-reviews with senior-engineering, or `docs/engineering/principles.md` in another tool.
4. Writes the report — `submitted` or `blocked` — and stops.

**The user** tells each session when to take its turn, reads the board's "waiting on the user" list,
decides, and may pause, redirect or override anything.

## When the coder stops and asks

Write the question into the report — status `blocked`, with options and a recommendation — and stop,
instead of guessing, when:

- the brief and its links still allow two readings that lead to different work;
- the brief, the spec, an ADR and the code disagree;
- a file outside the brief's scope needs to change;
- a new dependency seems necessary;
- a contract or schema would change;
- a security-relevant choice is not covered by the spec;
- the same fix has failed three times;
- an unrelated test starts failing;
- configuration or secrets are missing.

Ideas beyond the brief go into the report's *Proposals* section — never into the code.

## Ending the loop

1. **At most three rounds per brief.** After a third `changes-requested`, the lead either escalates to
   the user or supersedes the brief: it amends the plan (the step split or rewritten under new step
   numbers), opens their task folders for a fresh coder session, and marks the old brief `superseded`
   with a link to the new ones.
2. **Only blocking findings block**: an unmet acceptance criterion or requirement, an ADR violation, a
   failing test, a security issue, a regression. Everything else is recorded as non-blocking and
   deferred — to a later task, or to the proposal register.
3. **From round two, a review may only close earlier findings or flag regressions the fix introduced.**
   No new goalposts.
4. **A finding that reopens, or is disputed twice, escalates** to the user.
5. **Prefer a fresh coder session per task**, and per round once a session has grown long. Everything the
   coder needs is in the files; a long transcript only adds drift.
6. **A change is done** when every task is approved, the change's review (phase 6) is closed, the living
   specs are merged, and the user has accepted it.

## The user stays in control

- **`CONTROL.md`** — set `pause` or `stop`; every agent checks it at session start and before each handoff.
- **The board's "Waiting on the user" section** — every blocked question, proposal, proposed ADR and
  escalation, one line each with its link. That list is the user's inbox.
- **The user may edit any file.** The agents treat the files as the truth, including the user's edits.
- **No git writes, no migrations applied to a persistent database, no deploys, and no destructive
  commands without the user's yes.** Reading history and diffs is fine. If the user authorises commits,
  each agent commits only the files it owns.

## Mixed tools

Everything a coder in another tool needs lives in the project, not in anyone's skills folder:
`AGENTS.md` → `docs/handoff/PROTOCOL.md` (with the stop-and-ask list and the templates it links) → the
brief → the linked files. When the coder's tool cannot load these
skills, the lead writes `docs/engineering/principles.md` (senior-engineering `project-knowledge.md`) and
the stack playbook carries the stack rules. A tool that does not read `AGENTS.md` gets a shim. Keep
everything plain Markdown with relative links and no tool-specific syntax. Each report names the tool
and model that wrote it.

## Parallel coders

One coder by default. More than one only with disjoint files in scope, named in each brief; a separate
working copy or branch for each; and nothing merged that the user has not approved.
