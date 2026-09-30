# Phase 4 — Implementation plan

**Goal:** an ordered list of steps an implementer works through in sequence, where each step produces
something verifiable and the project is in a working state at the end of every one.

**Hard rule: the plan makes no new decisions.** It orders work the tech spec already specified. If a
step needs a decision, the tech spec is incomplete — go back and fix it there, then return. A plan
that decides things is a tech spec pretending to be a schedule.

Write to `docs/specs/04-implementation-plan.md`.

**Every step cites the requirement ids it implements**, and you fill in the `Plan steps` column of the
traceability matrix in `02-requirements.md`. That column is what makes an unimplemented `Must`
visible — see "Done when".

## How to order steps

**Vertical slices, not horizontal layers.** "All entities, then all repositories, then all services"
leaves nothing verifiable until the end and hides integration problems until they are expensive.
Prefer one capability working end to end, then the next.

**First step is a skeleton that runs.** Project structure, wiring, configuration, health check, one
trivial path proving the stack works. Everything after it has somewhere to land.

**Then, in this order of preference:** the flow with the most risk or the most unknowns first, while
there is time to discover the spec was wrong; then the flows the primary journey depends on; then
secondary capabilities; then hardening.

**Each step independently verifiable.** If a step's result can only be checked after two more steps,
the boundaries are wrong. Merge them or move the verification.

**One session per step.** A step should be completable and verifiable in one focused sitting. A step
estimated at several days is several steps.

**No step contains "and also".** A step that implements a feature and refactors something else and
adds logging is three steps, and its verification cannot fail cleanly.

**Dependencies stated, not implied.** Each step names which steps must be complete first, so an
implementer can see what is parallelizable and what is not.

## Step template

Every step, without exception:

```markdown
### Step N — <imperative title>

Status: not started | in progress | done | blocked
Depends on: <step numbers, or none>
Implements: <FR/NFR ids from 02-requirements.md>
Spec: <tech spec section numbers this builds>

**Goal.** One sentence: what exists after this that did not before.

**Components.** The rows from the tech spec component inventory this step
creates or changes, by name.

**Files.** Expected paths to create or modify.

**Details.** What specifically to build, referencing spec sections rather
than restating them. Anything the implementer would otherwise have to
infer.

**Verification.** The exact command or procedure, and the expected result.
Not "it builds" — the test that passes, the request and its expected
response, the row that appears, the log line.

**Done when.** Observable criteria, as a checklist.

**Notes.** Traps, ordering constraints, anything easy to get wrong here.
```

## Verification is per step and must be real

A step whose verification is "the project compiles" is unverified. Compilation proves syntax.

Acceptable verification, in rough order of strength: an automated test that fails before and passes
after; a **probe** — a throwaway script or project that drives the thing and reports what happened,
which is the answer wherever there is no test suite to add to or the behaviour only appears against a
real dependency; a request against the running system with a stated expected response; a database row
read back and compared; a log or metric observed; a manual procedure written out precisely enough that
someone else would perform it identically.

A probe verifies functional requirements as readily as non-functional ones — for an FR it checks the
acceptance criteria end to end, for an NFR it produces the number. State what the probe exercises and
what result counts as a pass, and record its output in the step; the probe itself is disposable and
does not belong in the deliverable tree.

State the **expected** result, not just the action. "Run the tests" is an instruction; "all tests
pass, including the three new ones named X, Y, Z" is a verification.

Include at least one negative case wherever the step implements a rule — the invalid input, the
absent value, the failure branch. A step verified only on the happy path has verified the case nobody
doubted.

## Document template

```markdown
# <Project> — Implementation Plan
Status: draft | approved   Version: n   Date: YYYY-MM-DD
Specs: 01-product-spec.md v<n>, 02-requirements.md v<n>,
       03-tech-spec.md v<n>

## Read first
For an implementer starting cold: read the product spec sections 1-6,
then all of 02-requirements.md, then the whole tech spec, then this
plan. Do not start at step 1 without the tech spec.

## Conventions
Build command, test command, run command, migration command, and any
project-specific rules the implementer must follow.

## Progress
| Step | Title | Implements | Status | Verified |
|---|---|---|---|---|

## Steps
<one block per step, using the step template>

## Deferred
Work deliberately out of this plan, and why.

## Amendment log
| Date | Change | Reason |
|---|---|---|
```

## Keep it alive

The plan is a working document, not a snapshot.

- **Update the status and the progress table as you go**, in the file. An implementer resuming after
  a break — or a different agent picking it up — must be able to see where things stand without
  reading the code or the chat.
- **Record the verification result**, not just that it was run.
- **When a step turns out wrong, amend the plan and log it.** Do not silently do something different;
  the next reader will trust the document.
- **If implementation reveals the tech spec is wrong**, stop, amend the tech spec, note it in the
  amendment log, then continue. See the orchestrator's "Amending an approved spec".

## Done when

- **Every `Must` requirement is implemented by at least one step**, and the matrix shows it. An empty
  `Plan steps` cell against a `Must` is the plan being incomplete, not the matrix being untidy.
- **Every requirement whose verification is a probe or a dedicated plan has a step that runs it**,
  with the passing result stated — the number for an NFR, the checked acceptance criteria for an FR.
  A requirement verified by an automated test is covered by the step that writes the test; one
  verified by structural check needs no step of its own, since the review covers it.
- Every component in the tech spec inventory is created by exactly one step.
- Every flow in the tech spec is exercised by at least one step's verification.
- Every step has real verification with an expected result.
- No step implements a requirement that does not exist, and none exists for no requirement.
- Step 1 leaves the project running.
- No step depends on a step that comes after it.
- No step introduces a decision.
- An implementer could start at step 1 with only this bundle and no access to you.

## Then stop and hand off

State that the bundle is complete, list the four file paths, and say what an implementing agent
should read first and in what order. Report the matrix's coverage — how many `Must` requirements have
steps, and any that do not. Do not start implementing unless asked — the user may be handing this to a
different agent or model, and that is the point of writing it this way.
