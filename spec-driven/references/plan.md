# Phase 4 — Implementation plan

**Goal:** an ordered list of steps an implementer works through in sequence, where each step produces
something verifiable and the project is in a working state at the end of every one.

**Hard rule: the plan makes no new decisions.** It orders work the tech spec already specified. If a
step needs a decision, the tech spec is incomplete — go back and fix it there, then return. A plan that
decides things is a tech spec pretending to be a schedule.

A plan belongs to a change: write it to `docs/changes/CH-NNN-<slug>/plan/` — `README.md` as the plan's
index, and one file per step in `steps/S-NN-<slug>.md`.

**Every step cites the requirement ids it implements**, and you fill in the traceability columns that
make an unimplemented `Must` visible — see "Done when".

## Contents
- How to order steps
- Step template
- Verification is per step and must be real
- The plan index
- Keep it alive
- Done when
- Then stop and hand off

## How to order steps

**Vertical slices, not horizontal layers.** "All entities, then all repositories, then all services"
leaves nothing verifiable until the end and hides integration problems until they are expensive. Prefer
one capability working end to end, then the next.

**First step is a skeleton that runs.** Project structure, wiring, configuration, health check, the
integration-test infrastructure (containers up, reset working), the architecture tests, and one trivial
path proving the stack works. Everything after it has somewhere to land.

**Then, in this order of preference:** the flow with the most risk or the most unknowns first, while
there is time to discover the spec was wrong; then the flows the primary journey depends on; then
secondary capabilities; then hardening.

**Each step independently verifiable.** If a step's result can only be checked after two more steps, the
boundaries are wrong. Merge them or move the verification.

**One session per step.** A step should be completable and verifiable in one focused sitting — and, in
multi-agent mode, it is exactly one task brief. A step estimated at several days is several steps.

**No step contains "and also".** A step that implements a feature and refactors something else and adds
logging is three steps, and its verification cannot fail cleanly.

**Dependencies stated, not implied.** Each step names which steps must be complete first, and whether
it can run in parallel with others (disjoint files, no dependency), so an implementer can see what is
parallelizable and what is not.

**Closing is not a plan step.** After the last step comes the change's review (phase 6), then the
user's acceptance, then the close (phase 7, `changes.md`): merge the deltas into the living specs and
archive the folder. The plan's last step leaves everything the review needs in place.

## Step template

Every step, without exception, in its own file:

```markdown
# S-NN — <imperative title>
Status: not started | in progress | done | blocked · Depends on: <S-NN, or none> · Parallel: yes | no
Implements: <FR/NFR ids> · Spec: <tech spec files this builds>
Summary: <one line: what this step delivers>

**Goal.** One sentence: what exists after this that did not before.

**Components.** The rows from the component inventory this step creates or changes, by name.

**Files in scope.** The paths to create or modify — nothing outside them without a question.

**Read first.** The exact spec files this step needs — at most six. An implementer reads these, not the
whole bundle.

**Details.** What specifically to build, referencing spec files rather than restating them. Anything the
implementer would otherwise have to infer.

**Tests.** Per lens that applies — business, technical, performance, security — and per other risk the
step carries (concurrency, idempotency, resilience, …), what the tests must try to break. Integration
tests with Testcontainers wherever the step crosses an external dependency.

**Verification.** The exact command or procedure, and the expected result. Not "it builds" — the tests
that pass by name, the request and its expected response, the row that appears, the log line.

**Done when.** Observable criteria, as a checklist.

**Notes.** Traps, ordering constraints, anything easy to get wrong here.

**Result.** Filled in when done: what was run, what it showed.
```

## Verification is per step and must be real

A step whose verification is "the project compiles" is unverified. Compilation proves syntax.

Acceptable verification, in rough order of strength: an automated test that fails before and passes
after; a **probe** — a throwaway script or project that drives the thing and reports what happened, the
answer wherever there is no suite to add to or the answer is a measurement; a request against the running
system with a stated expected response; a database row read back and compared; a log or metric observed;
a manual procedure written out precisely enough that someone else would perform it identically.

A probe verifies functional requirements as readily as non-functional ones — for an FR it checks the
acceptance criteria end to end, for an NFR it produces the number. State what the probe exercises and
what result counts as a pass, and record its output in the step; the probe itself is disposable and
does not belong in the deliverable tree.

State the **expected** result, not just the action. "Run the tests" is an instruction; "all tests pass,
including the three new ones named X, Y, Z" is a verification.

Include at least one negative case wherever the step implements a rule — the invalid input, the absent
value, the failure branch. A step verified only on the happy path has verified the case nobody doubted.

## The plan index

`plan/README.md`:

```markdown
# CH-NNN — Implementation plan
Status: draft | approved · Version: n · Date: YYYY-MM-DD
Specs: the living spec files and change deltas this plan builds, by path

## Read first
For an implementer starting cold: the product overview, the requirement files this change touches,
the tech spec files for its components, then this plan. Each step lists its own reading.

## Conventions
Build, test, integration-test, run and migration commands, and any project rules the implementer must
follow.

## Progress
| Step | Title | Implements | Depends on | Parallel | Status | Verified |
|---|---|---|---|---|---|---|

## Deferred
Work deliberately out of this plan, and why.

## Amendment log
| Date | Change | Reason |
|---|---|---|
```

## Keep it alive

The plan is a working document, not a snapshot.

- **Update the step status and the progress table as you go**, in the files. An implementer resuming after
  a break — or a different agent picking it up — must see where things stand without reading the code or
  the chat.
- **Record the verification result** in the step's *Result*, not just that it was run.
- **When a step turns out wrong, amend the plan and log it.** Never silently do something different; the
  next reader will trust the document.
- **If implementation reveals the tech spec is wrong**, stop, say what is wrong, and propose the
  amendment; with the user's yes, amend the spec, note it in the amendment log, then continue — see
  "Amending an approved spec" in the skill.

## Done when

- **Every `Must` requirement is implemented by at least one step**, and the matrix shows it. An empty cell
  against a `Must` is the plan being incomplete, not the matrix being untidy.
- **Every requirement verified by a probe or a dedicated plan has a step that runs it**, with the passing
  result stated. One verified by an automated test is covered by the step that writes the test.
- Every component in the inventory is created by exactly one step, and every flow is exercised by at
  least one step's verification.
- Every step has real verification with an expected result, its files in scope and its reading list.
- No step implements a requirement that does not exist, and none exists for no requirement.
- Step 1 leaves the project running; no step depends on a later one; no step introduces a decision.
- An implementer could start at step 1 with only the files and no access to you.

## Then stop and hand off

Run the pre-mortem (`discovery.md`) against the plan and fold its results in. Then state that the plan
is complete, list the plan index and the specs it builds, and say what an implementing agent should
read first. Report the matrix coverage — how many `Must` requirements have steps, and any that do not
— present the `assumed` entries, open questions and proposals, and ask for approval. Do not start implementing unless asked — the user may hand this to a
different agent, model or tool, and that is the point of writing it this way. In multi-agent mode, the
lead now turns the first steps into briefs (`multi-agent.md`).
