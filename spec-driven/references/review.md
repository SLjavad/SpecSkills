# Phase 6 — Review and feedback

**Goal:** find what the implementation got wrong while it is still cheap, record every finding in a
file, and close the loop so the same correction is never needed twice.

**Any agent can run this** — the spec author, the implementer, or a fresh one with no history. So it is
written to work from the artifacts alone: the living specs, the change folder, and the code. Never assume
the reviewer remembers the conversation, and never assume the fixer does either. A reviewer with no
memory of writing the code catches more than one that has; if the user has a choice, prefer that one.

Write findings to `docs/changes/CH-NNN-<slug>/reviews/R-NN/`: a `README.md` summary, plus one file per
group of lenses that produced findings:

| File | Lenses |
|---|---|
| `conformance.md` | requirement-gap, conformance, unverified, spec-defect |
| `correctness.md` | correctness, silent-risk, failure-path |
| `design.md` | design, domain, dependency, readability, leftover |
| `performance.md` | performance |
| `security.md` | security |
| `tests.md` | verification |

A small review keeps everything in `README.md`. In multi-agent mode each task also gets a per-task
review in its folder (`handoff-templates.md`); this phase reviews the whole change before it closes.

## Contents
- What to review against
- Finding format
- Verifying the requirements
- Spec defects are findings too
- Improvements are proposals
- The loop
- Feed it forward
- Done when
- Reporting

## What to review against

**The spec, first and above taste.** The tech spec is the agreed design. A deviation from it is a finding,
even when the code is arguably better — because the document is now wrong, and the next reader will
trust it.

Then, in order:

1. **Requirement coverage — start at the matrix, not the code.** Every `Must` with no plan step, no
   component, or an empty verification cell is a finding before you have opened a single source file —
   the cheapest finding you will ever raise. Then check the claims: a row saying `implemented` whose
   acceptance criteria are not actually met is worse than an empty row.
2. **Spec conformance.** Does what was built match the files it claims to implement? Are all the
   inventory's components present, with the responsibilities described?
3. **Correctness.** The rules and algorithms against their worked examples. The edge cases the spec
   listed. Off-by-one, rounding direction, null handling, ordering, tie-breaks.
4. **Requirement verification, FR and NFR** — see below. The part most often skipped, and the part where
   a confident "verified" is most often unearned.
5. **Design, domain and dependencies** — senior-engineering's `review.md`: SOLID, the dependency rule,
   the rich domain model, dependencies in the code and in the packages. Architecture tests present and
   passing where an ADR names them.
6. **Algorithms and efficiency** — the same file: complexity at the spec's stated scale, data access,
   allocation, blocking, contention. Every finding carries evidence.
7. **Security — always.** senior-engineering's `security.md` audit, against the diff and against the
   tech spec's threat model: is every mitigation implemented and tested; did the change add a trust
   boundary or data class the model does not know about?
8. **Silent-wrongness risk.** For each change: if this were exactly backwards, what would tell us?
   Anything where the answer is "nothing" is a finding regardless of whether it is currently correct.
9. **Failure paths.** Every step of every flow — is the failure behaviour the spec specified actually
   implemented, or only the happy path? Every FR's stated failure behaviour, too.
10. **Verification gaps and test quality** — senior-engineering's `testing.md`. Steps marked verified
    whose verification does not prove what it claims. The four lenses missing on a significant flow.
    Integration tests against substitutes instead of the real engine. Tests that assert nothing, mirror
    the implementation, cannot fail, or were weakened. Surviving mutants on the core.
11. **Readability and balance.** Over-fragmentation and over-coupling both — the entry-point test from
    senior-engineering's `design.md`.
12. **Leftovers.** Debug output, commented-out code, `TODO`s, scaffolding, unused imports, dead
    abstractions with no caller.
13. **The documents tell the truth.** The change deltas, ADRs and area records match the code, so the
    merge at close (`changes.md`) will leave the living specs correct.

## Finding format

Every finding, in the file:

```markdown
### F-NN — <short title>
Severity: blocker | major | minor | note · Blocking: yes | no · Introduced by this change: yes | no
Lens: requirement-gap | conformance | correctness | unverified | design | domain | dependency |
      performance | security | silent-risk | failure-path | verification | readability | leftover |
      spec-defect
Requirement: <FR/NFR id, where the finding is against one>
Location: <path>:<line>  (or the spec file and id, for a spec defect)
Status: open | fixed | rejected | deferred

**What.** The defect, in one or two sentences.

**Why it matters.** The concrete consequence — the input, state or sequence that produces a wrong
result. If you cannot name one, downgrade to note.

**Evidence.** What you ran or read that shows it: the test, the request and response, the measurement.

**Suggested fix.** What to change. Not a rewrite of the whole area.

**Outcome.** Filled in by whoever acts on it: what was done, or the written reason for rejecting it.
```

A **security** finding also records the exploit input, the impact, the OWASP/ASVS/CWE reference, the
regression test that proves the fix, and a `Rating:` line — a CVSS vector for a concrete vulnerability,
likelihood × impact for a design risk. A critical or high rating is always severity `blocker`.

`F-` ids are scoped to the change and allocated in one sequence by the reviewer across the change's
task reviews and phase-6 reviews: cite them as `CH-007/F-12`.

**Severity means something.** A blocker produces wrong data, loses money, breaks a contract, or opens a
security hole. A major is a real defect on a reachable path. A minor is a defect on an unlikely path or a
genuine readability problem. A note is an observation with no defect behind it — keep these few, or they
train the reader to skim.

**No finding without a consequence.** "This could be cleaner" is not reviewable. Name the input that
breaks it, or the specific thing a reader misunderstands. And **do not manufacture findings** — a
reviewer told to find problems finds some; a clean lens is a valid result, with what you checked.

## Verifying the requirements

Take each requirement's `Verification` field and actually do it — **functional as well as
non-functional**. An unverified requirement is reported as unverified, never as met.

- **Functional requirements: exercise the acceptance criteria, do not read them.** Where a test covers a
  criterion, run it and name it. Where none does, a probe is the cheap answer — drive the flow against the
  real database, provider and bus, and check each criterion including the stated failure behaviour.
  Record the request and what came back. **"The implementation looks correct" is not verification of an
  FR** and must not be recorded as one.
- **Non-functional requirements: produce the number.** A probe or load test that measures, compared
  against the target — a loop timing a query, a capture of the emitted SQL and its plan, a payload
  measured after a serializer round-trip, a run at 10× volume to see whether the algorithm stays linear.
- **For either kind, say what the probe ran against.** A probe over fabricated data proves less than one
  over real data, and the difference belongs in the finding. Keep the probe out of the deliverable tree.
- **Structural check.** Where nothing above reaches the outcome, confirm the mechanism exists — the index,
  the timeout, the bound, the exclusion — then write down that the mechanism was checked and the outcome
  was not. Reporting a structural check as a measurement is the specific dishonesty this section exists
  to prevent.
- **Dedicated plan.** If the tech spec specified one and it was not run, that is an open finding, not a
  footnote.
- **Not verified.** Fine, if the entry says so and says what would be needed. A blank cell is not this.

A requirement whose criteria were checked and **missed** is a finding at the severity its consequence
deserves — for an NFR, read the `Consequence if missed` field it already carries rather than guessing.

## Spec defects are findings too

If the implementation is right and the spec is wrong, that is a `spec-defect` finding against the
document, located by file and id. It is fixed by amending the spec — keeping the superseded decision
visible with the reason it changed, through a superseding ADR where the decision was one — never by
quietly letting the code diverge.

This is the most valuable category the review produces, because an approved spec that disagrees with
working code is worse than no spec: it actively misleads everyone who reads it next.

## Improvements are proposals

An optimization, a refactor, an upgrade or a better design that is not a defect is **not a finding**. It
goes to the proposal register (`discovery.md`) in that register's format — with its evidence, expected
gain, cost, risk and verification — and waits for the user. Nothing is changed because a reviewer preferred it.

## The loop

1. **The reviewer writes all findings to the files** before any fixing starts. Reviewing and fixing in the
   same pass produces a shallow review, because the reviewer starts optimising for what is easy to fix.
2. **Present a summary**: counts by severity, and the blockers by name.
3. **The fixer works the findings in severity order**, filling in `Outcome` on each and setting `Status`.
   In multi-agent mode the coder never edits a review: it reports each outcome in its next report, and
   the lead records `Outcome` and `Status`.
4. **Rejections need a written reason**, in the file. "Deliberate because X" is a legitimate outcome and
   becomes an area-record entry — see below.
5. **Re-check only what changed.** Verify each fix against the finding that prompted it; do not re-review
   untouched code.
6. **Close the review** with a line stating what remains open and why.

Findings live in files, not in chat. A session ends; the file does not.

## Feed it forward

The point of recording feedback is that the correction is not needed a second time.

- **A rejected finding that was actually deliberate** belongs in the area record, with the failure it
  prevents. That is what stops the next reviewer — or the next agent — "fixing" it.
- **A finding that recurs across reviews** is not an implementation problem; it is a missing rule. Add it
  to the area record, the stack playbook, `AGENTS.md`, or an architecture test, so it is prevented
  rather than caught.
- **A whole category of finding appearing repeatedly** means the spec was too vague in that area. Note
  it, so the next change's tech spec covers it up front.

## Done when

- Every blocker and major is fixed, or rejected with a written reason.
- Every fix has been verified against the finding that prompted it.
- Every `Must` requirement has been checked against its acceptance criteria, not just against the matrix
  saying `implemented`.
- Every requirement — FR and NFR — has a verification outcome recorded: the test that ran, the probe
  result and what it ran against, an explicit "mechanism checked, outcome not measured", or an explicit
  "not verified, needs X". No blanks.
- The security lens ran and its critical and high findings are closed.
- Every spec defect is amended in the spec, not just in the code.
- Anything deliberate that looked wrong is recorded where the next reader will find it.
- The remaining open findings are listed with the reason each is still open.

## Reporting

Counts by severity, blockers by name, what was fixed, what was rejected and why, what remains open, the
proposals raised, and any rule added to a record. Short — the files hold the detail.

Never report a review as clean without saying what you actually checked. "No issues found" after reading
three files is not a review, and saying so is more useful than the reassurance.
