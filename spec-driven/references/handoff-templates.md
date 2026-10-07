# Handoff templates

The files of the multi-agent loop. At setup, write into the project, adjusted to it:

- `docs/handoff/PROTOCOL.md` and `docs/handoff/BOARD.md`;
- `docs/handoff/templates/step.md`, `report.md`, `review.md` and `prompts.md` — the shape of every
  file of that kind in a task folder, and the handoff prompts.

The coder's instructions are the plan step itself; there is no brief. `templates/step.md` is
`plan.md`'s step template written out in full, with a second line, `Status:`, for a small change,
whose step.md has no progress table to hold it — the values in PROTOCOL's "Step status".
`PROTOCOL.md` links the templates, so an agent in any tool finds every rule and format inside the
project. Plain Markdown, no tool-specific syntax, and every path written from the repository root.

## Contents
- PROTOCOL.md
- Handoff prompts
- BOARD.md
- report.md
- review.md

## PROTOCOL.md

```markdown
# Handoff protocol
Status: approved by <the user>, YYYY-MM-DD · Owner: the user
Summary: How the lead and coder agents work together on this project through files. Every agent reads
this first.

## Roles
- **Lead** (<tool>): product manager, tech lead, architect, reviewer. Writes the specs, ADRs (as
  proposed), docs/discovery/, plans and their progress table, steps (a small change's step.md too),
  reviews, BOARD.md, docs/engineering/ and docs/handoff/templates/, and updates the docs a change
  affects. Never edits production code or tests.
- **Coder** (<tool>): implements steps; writes code, tests and reports. Never edits any document —
  specs, plans, steps, ADRs, registers, reviews, BOARD.md, AGENTS.md, docs/engineering/ — and lists the
  ones a change affects in its report.
- **User**: owns this file, starts every session and carries each handoff prompt, decides everything
  outside the approved spec, accepts each change.

## Handoffs
Agents never start each other. Each turn ends with a handoff prompt for the user to paste into the next
session (docs/handoff/templates/prompts.md). The coder is always a separate session the user starts —
never a subagent, background agent or workflow launched by the lead.

## Start of every session in the implementation loop (phase 5 on)
- Lead: docs/handoff/BOARD.md, then the active change's progress table (its plan/README.md) or the
  small change's step.md, then the task folder whose turn it is. The task folder, not the status,
  decides the turn — the status may lag behind a report that was just submitted.
- Coder: the step the handoff prompt names.
- Both: the files the step links, the engineering rules (<the senior-engineering skill |
  docs/engineering/principles.md>) and the stack playbook (docs/engineering/stack-<name>.md).

## Step status
A step's status is in its plan's progress table — for a small change, in its step.md's Status line.
Only the lead writes it, and only these values:
- `planned`, `ready`, `escalated`, `superseded by S-NN`;
- `done YYYY-MM-DD, re-run pass`, with `at <short commit>` after the date if the work was already
  committed;
- `done YYYY-MM-DD, re-run pass except <check> — waiting on the user`, when part of the verification
  only the user can run; the check is listed under "Waiting on the user". When it passes, the lead
  drops the `except` part; when it fails, the lead writes a `changes-requested` review and sets the
  step back to `ready`.
A coder at work or blocked shows in its report, never in the status.

## Whose turn
- step `ready`, no report → coder
- report `in progress` → coder, still working
- report `submitted`, no review for that round, step still `ready` → lead
- report `blocked` → lead, or the user if the question needs them
- review `changes-requested` or `answered` → coder, next round
- step `done` → done; an approval writes no review file
- step `escalated` → the user; once the user decides, the lead writes the next review or supersedes
  the step

## Files and formats
The instructions: docs/changes/CH-NNN-<slug>/plan/steps/S-NN-<slug>.md. The task folder, same name:
docs/changes/CH-NNN-<slug>/tasks/S-NN-<slug>/ — or docs/handoff/tasks/YYYY-MM-DD-<slug>/ for a small
change, holding its own step.md — with report-01.md, a review-01.md only when the coder must act, then
report-02.md, … Formats: docs/handoff/templates/step.md, report.md and review.md.
One writer per file. Once submitted, a file's content is frozen — a correction is a new file. Two
exceptions: the file's writer still updates its status line, and the user may fill in decision fields
anywhere.

## The lead decides only what the approved spec already answers
New ideas, ADR acceptance, new or upgraded dependencies, changes to scope, requirements, acceptance
criteria, contracts or schemas, and security-posture changes wait for the user.

## The coder stops and asks — a `blocked` report with options and a recommendation — when
- the step and its links still allow two readings that lead to different work;
- the step, the spec, an ADR and the code disagree;
- a file outside the step's files in scope needs to change;
- a new dependency seems necessary;
- a contract or schema would change;
- a security-relevant choice is not covered by the spec;
- the same fix has failed three times;
- an unrelated test starts failing;
- configuration, secrets or a required tool (such as Docker) is missing.

## Rules
- Ideas beyond a step are proposals in the report — never code.
- Never delete or weaken a test to make work pass; every changed test states its reason.
- The coder lists the docs a change affects in its report; the lead updates them.
- The lead re-runs the verification commands before approving.
- Each fact is written once. The report holds the evidence; on approval the lead writes only the step's
  `done …` status, and no review file. A review file is written only when the coder must act
  (`changes-requested` or `answered`). An escalation marks the step `escalated` and the board says why;
  once the user decides, the next review — or the plan amendment or superseding step's Notes — quotes
  the reason and the decision.
- A commit that lands a step's work names the step id (CH-NNN/S-NN, or the small change's task id).
- Only blocking findings block, and every blocker or major finding is blocking. A round is one report
  and the lead's response; an `answered` review does not count. From the second round a review only
  closes findings or flags regressions from the fix. Instead of a third `changes-requested` the lead
  marks the step `escalated`, or splits or rewrites it — new steps and task folders, the old step
  marked `superseded by …`.
- A non-blocking defect goes to a later step; where none will touch it, it becomes a Known defect on
  the requirement it breaks, fixed by a small change when the user says so. A note with no consequence
  is dropped; an improvement goes to docs/discovery/proposals.md.
- A finding that reopens, or is disputed twice, escalates to the user.
- End every turn with the handoff prompt, then stop.
- Never put secrets, personal data, internal hostnames or proprietary code in these files, or in any web
  search, web fetch or remote tool call.
- No git writes, no migrations applied to a persistent database, no deploys and no destructive commands
  without the user's yes. Reading history and diffs is fine.
```

## Handoff prompts

`docs/handoff/templates/prompts.md` — the agent fills in the paths and prints the prompt for the user
to paste into a new session. It points at files and copies nothing.

```markdown
## To the coder
You are the coder on <project>. Read docs/handoff/PROTOCOL.md, then the step
<path to the step file> and the files it links. Implement it within its files in scope, verify it as it
says, write <task folder>/report-NN.md, give me the handoff prompt for the lead, and stop.

## To the coder, next round
You are the coder on <project>. Read docs/handoff/PROTOCOL.md, then <task folder>/review-NN.md, the
step <path to the step file> and the files they link. Address every finding and answer, verify as the
step says, write <task folder>/report-NN.md (the next round), give me the handoff prompt for the lead,
and stop.

## To the lead
You are the lead on <project>. Read docs/handoff/PROTOCOL.md, then <task folder>/report-NN.md.
Re-run its verification and review the diff. Write <task folder>/review-NN.md only if the coder must
act; if approved, mark the step done in the progress table, or a small change's step.md. Update
docs/handoff/BOARD.md if anything now waits on me, give me the next handoff prompt if there is one, and
stop.
```

## BOARD.md

```markdown
# Board
Updated: YYYY-MM-DD HH:MM UTC by the lead

## Active
- CH-007 — <title> — progress: docs/changes/CH-007-<slug>/plan/README.md
- Small change 2026-10-06-<slug> — docs/handoff/tasks/2026-10-06-<slug>/step.md

## Waiting on the user
- Q-014 — <one line> — docs/discovery/questions.md
- ADR-0006 (proposed) — <one line> — docs/adr/0006-<slug>.md
- CH-007/S-04 — escalated after round 3 — <the open finding, in one line>
- CH-007/S-05 — your check: <the verification only you can run> — <path to the step file>
```

The board holds no task status — the progress table does. A change leaves "Active" when it is
archived, and a small change when its step is `done`. Waiting items cite tasks by id, never by folder
path, because a change's folder moves when it is archived.

## report.md

```markdown
# Report CH-007/S-02 — round 1
Status: in progress | submitted | blocked · Tool and model: <…> · Base: <commit> · Head: <commit or "uncommitted">

## Summary
## Response to the previous review (from round 2)
| F | Fixed or disputed | Evidence or reason |
|---|---|---|
## Acceptance evidence
| Criterion | Test or command | Result |
|---|---|---|
## Files changed
## Tests added or changed
Every changed or removed assertion, with its reason.
## Decisions within latitude
## Deviations from the step, and why
## Questions (blocking)
Each with options and a recommendation.
## Proposals (not implemented)
## Docs affected, and spec defects noticed
For the lead to update.
## Risks, and what I could not verify
```

The acceptance evidence is the one record of the step's result; nothing else copies it.

## review.md

Written only when the coder must act. An approval or an escalation has no review file.

```markdown
# Review CH-007/S-02 — round 1
Verdict: changes-requested | answered · Reviewed: <commit> · Verification re-run: <commands and result>
(`answered`: the report's questions are answered below and the coder continues in the next round)

## Findings
| F | Severity | Blocking | Against (AC / FR / ADR / lens) | Evidence (file:line, input) | Required change |
|---|---|---|---|---|---|

## Closed from earlier rounds
Each with its outcome.
## Deferred, non-blocking
Where each one went: a later step, a Known defect on FR-/NFR-NNN, or P-NNN.
## Answers to questions
## Rationale
```
