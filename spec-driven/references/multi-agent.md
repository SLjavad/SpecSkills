# Multi-agent mode — lead and coder

**Goal:** two or more agents — possibly in different tools, in separate sessions — build the project
together through files alone, in a loop that improves both the decisions and the code. The user carries
every handoff, so nothing runs without them, and can see, approve or override anything at any point.

## Contents
- Why it pays, and what it costs
- Roles and ownership
- What the lead may decide
- The files
- Whose turn is it
- Handing over: the user carries a prompt
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
| **User** | `PROTOCOL.md`; starts every session and carries each handoff prompt; decides every question, proposal and ADR outside the approved spec; approves gates; accepts each change | — |
| **Lead** — product manager, tech lead, architect, reviewer | `AGENTS.md` and `CLAUDE.md` (the user approves changes), specs and change deltas, plans and their progress table, ADRs (as proposed), `docs/discovery/` (the understanding and the registers), `docs/engineering/`, `docs/handoff/templates/`, `BOARD.md`, reviews | edits production code or tests; launches an agent to write them |
| **Coder** — a separate session the user starts, in any tool | code, tests, reports | runs as a subagent of the lead; edits any document — specs, plans, ADRs, registers, reviews, the board, `AGENTS.md`, `docs/engineering/`; deletes or weakens a test to make work pass |

**One writer per file.** Once a file is submitted its content is frozen; a correction is a new file —
the next report round, a new task folder — never an edit to someone else's. Two exceptions: the owner
keeps updating the file's status line as the work moves, and the user may fill in decision fields in
any file. The lead records a decision the user gave in the lead's session (see below).

**The coder never edits a document, so it lists the docs a change affects** in its report; the lead
updates them.

## What the lead may decide

Only what stays inside the approved spec:

- answer a coder's question the spec already answers, citing where;
- accept or reject the coder's choices within the step's stated latitude;
- order and split tasks, write feedback, request changes.

Everything else waits for the user: the lead marks the step `escalated` — or leaves a step not yet
handed over `planned` — and lists the item under "Waiting on the user":

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
docs/handoff/BOARD.md         lead: the active work and the "waiting on the user" list
docs/handoff/templates/       report.md, review.md, prompts.md — the formats, inside the project
docs/changes/CH-NNN-<slug>/
  plan/README.md              lead: the progress table — the one status of every step
  plan/steps/S-NN-<slug>.md   lead: the coder's instructions — the plan step itself
  tasks/S-NN-<slug>/          one per step, same name:
    report-01.md              coder: what was done, and the evidence
    review-01.md              lead: only when the coder must act — findings or answers
    report-02.md, review-02.md, …
```

**The plan step is the instruction.** There is no separate brief: the coder reads the step and the files
it links, so nothing is copied out of the plan and nothing drifts from it. The step files do not change
during development, except through a logged plan amendment.

**A small change has no change folder and no plan**, so its task folder is
`docs/handoff/tasks/YYYY-MM-DD-<slug>/` and holds a `step.md` — `plan.md`'s step template, citing the
living-spec ids it touches, with its own `Status:` line, since there is no progress table to hold it.

Templates are in `handoff-templates.md`; the step template is in `plan.md`.

## Whose turn is it

Computed from the files, never from memory:

| State | Turn |
|---|---|
| step `ready` in the progress table, no report yet | coder |
| latest report `in progress` | coder — still working |
| latest report `submitted`, no review for that round, step still `ready` | lead |
| latest report `blocked` | lead — or the user, if the question needs them |
| latest review `changes-requested` or `answered` | coder — the next round |
| step `done` | done — approved, with no review file |
| step `escalated` | the user; once the user decides, the lead writes the next review or supersedes the step |

**A round** is one report and the lead's response to it. `answered` means the review only answers the
report's questions; it does not count as a round. The task folder decides whose turn it is — the
progress table may lag behind a report that was just submitted.

Every session of the implementation loop (phase 5 on) starts the same way. The lead reads `BOARD.md`,
then the active change's progress table, then only the task folder whose turn it is. The coder reads the
step its handoff prompt names. Both then read the files the step links, the engineering rules and the
stack playbook — nothing more by default.

## Handing over: the user carries a prompt

Agents never start each other. Each turn ends with a **handoff prompt** — a few lines the user pastes
into the next session (template in `handoff-templates.md`): the lead's, when a step is `ready` or a
review asks for another round; the coder's, when its report is `submitted` or `blocked`. The prompt
points at files and copies nothing. Nothing runs until the user passes a prompt on, so holding,
redirecting or stopping the loop needs no switch: the user simply waits, edits the prompt, or stops.

**The coder is never a subagent.** Implementation always happens in a separate session the user starts
— possibly another tool, another model or another machine. The lead never launches a subagent,
background agent or workflow to write code, and does not offer to; it hands over the prompt and stops.

## The loop

**The lead**
1. Checks the next `planned` step is ready to hand over: no unresolved `Q-` citations in its files,
   every acceptance criterion testable, the files in scope, the latitude and the verification commands
   named. A gap is fixed by amending the step, logged in the plan. Marks it `ready` in the progress
   table and gives the user the handoff prompt for the coder.
2. When a report is submitted: reads the report, reads the diff, and **re-runs the verification commands
   itself** — the report is a claim; the run is evidence. Reviews the diff with spec-driven's
   `references/review.md` and senior-engineering's `references/review.md`, `security.md` and
   `testing.md`, at the scale of the task.
3. **Writes a review file only when the coder must act**: `changes-requested` (blocking findings only)
   or `answered`. On approval there is no review file, and the result is not copied anywhere: the
   report holds the evidence, and the lead writes one cell — the step's status, `done YYYY-MM-DD,
   re-run pass` — then sends any non-blocking finding to a later step or the proposal register. An
   escalation is no file either: the step is marked `escalated` and the board says why. The lead
   updates the docs the report lists as affected, and for another round gives the user the handoff
   prompt for the coder.

**The coder**
1. Reads the step its handoff prompt names, and the files it links — nothing more by default.
2. Implements within the files in scope, writes the tests the step's lenses call for, and verifies
   exactly as the step says.
3. Self-reviews with senior-engineering, or with `docs/engineering/principles.md` where the skills are
   not installed.
4. Writes the report — `submitted` or `blocked` — gives the user the handoff prompt for the lead, and
   stops.

**The user** carries each handoff prompt to the next session, reads the board's "waiting on the user"
list, decides, and may redirect or override anything.

## When the coder stops and asks

Write the question into the report — status `blocked`, with options and a recommendation — and stop,
instead of guessing, when:

- the step and its links still allow two readings that lead to different work;
- the step, the spec, an ADR and the code disagree;
- a file outside the step's files in scope needs to change;
- a new dependency seems necessary;
- a contract or schema would change;
- a security-relevant choice is not covered by the spec;
- the same fix has failed three times;
- an unrelated test starts failing;
- configuration, secrets or a required tool (such as Docker) is missing.

Ideas beyond the step go into the report's *Proposals* section — never into the code.

## Ending the loop

1. **At most three rounds per step.** Instead of a third `changes-requested`, the lead marks the step
   `escalated` — or supersedes it: it amends the plan (the step split or rewritten under new step
   numbers, with their rows in the progress table), opens their task folders for a fresh coder session,
   and marks the old step `superseded by S-NN, S-NN`.
2. **Only blocking findings block**: an unmet acceptance criterion or requirement, an ADR violation, a
   failing test, a security issue, a regression — and every finding of severity blocker or major. A
   non-blocking defect is deferred to a later step; only an improvement that is not a defect goes to
   the proposal register.
3. **From the second round, a review may only close earlier findings or flag regressions the fix
   introduced.** No new goalposts.
4. **A finding that reopens, or is disputed twice, escalates** to the user.
5. **Prefer a fresh coder session per task**, and per round once a session has grown long. Everything the
   coder needs is in the files; a long transcript only adds drift.
6. **The change's review (phase 6) runs in the lead role** — the lead, or a fresh session acting as
   one. Its blocking findings reach the coder as a fix step, `plan/steps/R-NN-fixes.md`, listing the
   finding ids, with its row in the progress table and its folder `tasks/R-NN-fixes/`; the lead
   allocates every `F-` id.
7. **A change is done** when every step is `done` or `superseded`, the change's review (phase 6) is
   closed, the living specs are merged, and the user has accepted it.

## The user stays in control

- **Handoff prompts** — no session starts until the user passes one on; to hold the loop, don't.
- **The board's "Waiting on the user" section** — every blocked question, proposal, proposed ADR and
  escalation, one line each with its link. That list is the user's inbox.
- **The user may edit any file.** The agents treat the files as the truth, including the user's edits.
- **No git writes, no migrations applied to a persistent database, no deploys, and no destructive
  commands without the user's yes.** Reading history and diffs is fine. If the user authorises commits,
  each agent commits only the files it owns.

## Mixed tools

Everything a coder without these skills needs lives in the project, not in anyone's skills folder:
`AGENTS.md` → `docs/handoff/PROTOCOL.md` (with the stop-and-ask list and the templates it links) → the
step → the linked files. When the coder works without these skills installed, the lead writes
`docs/engineering/principles.md` (senior-engineering `project-knowledge.md`) and the stack playbook
carries the stack rules. A tool that does not read `AGENTS.md` gets a shim. Keep
everything plain Markdown with paths from the repository root and no tool-specific syntax. Each report
names the tool and model that wrote it.

## Parallel coders

One coder by default. More than one only with disjoint files in scope, named in each step; a separate
working copy or branch for each; and nothing merged that the user has not approved.
