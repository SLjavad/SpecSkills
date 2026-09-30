# Handoff templates

The files of the multi-agent loop. At setup, write into the project, adjusted to it:

- `docs/handoff/PROTOCOL.md`, `docs/handoff/BOARD.md`, and `docs/handoff/CONTROL.md` — created with
  `Mode: pause`; only the user switches it to `run`;
- `docs/handoff/templates/brief.md`, `report.md` and `review.md` — the shape of every file of that kind
  in a change's `tasks/` folder.

`PROTOCOL.md` links the templates, so an agent in any tool finds every rule and format inside the
project. Plain Markdown, no tool-specific syntax, and every path written from the repository root.

## Contents
- PROTOCOL.md
- CONTROL.md
- BOARD.md
- brief.md
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
  proposed), the question and proposal registers, plans, briefs, reviews, BOARD.md and docs/engineering/,
  and updates the docs a change affects. Never edits production code or tests.
- **Coder** (<tool>): implements briefs; writes code, tests and reports. Never edits specs, plans, ADRs,
  registers, briefs, reviews or BOARD.md.
- **User**: owns this file and CONTROL.md, decides everything outside the approved spec, accepts each
  change.

## Start of every session
1. Read docs/handoff/CONTROL.md. Unless it says `run`, stop and say why.
2. Read docs/handoff/BOARD.md for the list of tasks. The task folder, not the board, decides whose turn
   it is — the board may lag behind a report that was just submitted.
3. Read the task folder, the files its brief links, the engineering rules (<the senior-engineering
   skill | docs/engineering/principles.md>) and the stack playbook (docs/engineering/stack-<name>.md).

## Whose turn
- brief `ready`, no report → coder
- report `in-progress` → coder, still working
- report `submitted`, no review for that round → lead
- report `blocked` → lead, or the user if the question needs them
- review `changes-requested` or `answered` → coder, next round
- review `approved` → done
- review `escalated` → the user; once the user decides, the lead writes the next review or supersedes
  the brief

## Files and formats
Task folder: docs/changes/CH-NNN-<slug>/tasks/S-NN-<slug>/ holding brief.md, report-01.md,
review-01.md, report-02.md, … Formats: docs/handoff/templates/brief.md, report.md, review.md.
One writer per file. Once submitted, a file's content is frozen — a correction is a new file. Two
exceptions: the owner still updates its status line, and the user may fill in decision fields anywhere.

## The lead decides only what the approved spec already answers
New ideas, ADR acceptance, new or upgraded dependencies, changes to scope, requirements, acceptance
criteria, contracts or schemas, and security-posture changes wait for the user.

## The coder stops and asks — a `blocked` report with options and a recommendation — when
- the brief and its links still allow two readings that lead to different work;
- the brief, the spec, an ADR and the code disagree;
- a file outside the brief's scope needs to change;
- a new dependency seems necessary;
- a contract or schema would change;
- a security-relevant choice is not covered by the spec;
- the same fix has failed three times;
- an unrelated test starts failing;
- configuration or secrets are missing.

## Rules
- Ideas beyond a brief are proposals in the report — never code.
- Never delete or weaken a test to make work pass; every changed test states its reason.
- The coder lists the docs a change affects in its report; the lead updates them.
- The lead re-runs the verification commands before approving.
- Only blocking findings block. From round two a review only closes findings or flags regressions from
  the fix. After three `changes-requested` rounds (`answered` does not count) the lead splits or
  rewrites the step — new task folders, the old brief marked `superseded` — or escalates to the user.
- A finding that reopens, or is disputed twice, escalates to the user.
- Check CONTROL.md again before every handoff.
- Never put secrets, personal data, internal hostnames or proprietary code in these files, or in any web
  search, web fetch or remote tool call.
- No git writes, no migrations applied to a persistent database, no deploys and no destructive commands
  without the user's yes. Reading history and diffs is fine.
```

## CONTROL.md

```markdown
# Control
Mode: pause                     (run | pause | stop — created paused by the lead; only the user changes it)
Note: <optional instruction from the user to every agent>
Updated: YYYY-MM-DD by <the user>
```

## BOARD.md

```markdown
# Board
Updated: YYYY-MM-DD HH:MM UTC by the lead · Active change: CH-NNN

## Waiting on the user
- Q-014 — <one line> — docs/discovery/questions.md
- ADR-0006 (proposed) — <one line> — docs/adr/0006-<slug>.md
- CH-007/S-04 — escalated after round 3 — docs/changes/CH-007-<slug>/tasks/S-04-<slug>/review-03.md

## Tasks
| Task | Title | Status | Turn | Round | Folder |
|---|---|---|---|---|---|
| CH-007/S-01 | Skeleton runs | approved | — | 1 | docs/changes/CH-007-<slug>/tasks/S-01-<slug>/ |
| CH-007/S-02 | Cancellation window rule | changes-requested | coder | 2 | docs/changes/CH-007-<slug>/tasks/S-02-<slug>/ |
```

## brief.md

```markdown
# Brief CH-007/S-02 — <imperative title>
Status: draft | ready | done | superseded | cancelled · Round limit: 3
Summary: <one line: what this task delivers>
Step: docs/changes/CH-007-<slug>/plan/steps/S-02-<slug>.md · Implements: FR-014, FR-031, NFR-003 · ADRs: ADR-0004

## Objective
One or two sentences: what exists after this task that did not before.

## Acceptance
The criteria this task must meet, by id — AC-014.1, AC-014.2, AC-031.1 — linked, not copied.

## Read first
At most six files; nothing else by default.
- docs/changes/CH-007-<slug>/plan/steps/S-02-<slug>.md
- docs/specs/02-requirements/functional/booking.md (FR-014)
- docs/changes/CH-007-<slug>/requirements.md (FR-031, added by this change)
- docs/specs/03-tech/domain/booking.md
- docs/engineering/stack-<name>.md

## Scope
In: <the paths the coder may change>
Out: <what not to touch, and why>

## Latitude
Decide yourself: <internal structure, naming, local algorithm choices that satisfy the contracts>.
Not yours to decide: everything PROTOCOL.md reserves for the user.

## Tests required
Business: <…> · Technical: <…> · Performance: <…> · Security: <…>
Other risks this task carries (e.g. concurrency, idempotency, resilience — whatever applies): <…>
(write "not applicable — <reason>" for a lens that does not apply)
Integration tests with Testcontainers, one container per external dependency touched: <from the stack playbook>

## Verification
The exact commands and the expected result: the tests that must pass, by name; the request and its
expected response.

## Done when
- [ ] every listed acceptance criterion has evidence in the report
- [ ] the verification commands pass as stated
- [ ] no test deleted or weakened; every changed test has its reason
- [ ] self-review done against the engineering rules

## Stop and ask if
The list in PROTOCOL.md, plus anything specific to this task.
```

## report.md

```markdown
# Report CH-007/S-02 — round 1
Status: in-progress | submitted | blocked · Tool and model: <…> · Base: <commit> · Head: <commit or "uncommitted">

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
## Deviations from the brief, and why
## Questions (blocking)
Each with options and a recommendation.
## Proposals (not implemented)
## Docs affected, and spec defects noticed
For the lead to update.
## Risks, and what I could not verify
```

## review.md

```markdown
# Review CH-007/S-02 — round 1
Verdict: approved | changes-requested | answered | escalated · Reviewed: <commit> · Verification re-run: <commands and result>
(`answered`: the report's questions are answered below and the coder continues in the next round)

## Findings
| F | Blocking | Against (AC / FR / ADR / lens) | Evidence (file:line, input) | Required change |
|---|---|---|---|---|

## Closed from earlier rounds
Each with its outcome.
## Deferred, non-blocking
Where each one went: a later task, or P-NNN.
## Answers to questions
## Rationale
```
