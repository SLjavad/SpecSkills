# Phase 6 — Review and feedback

**Goal:** find what the implementation got wrong while it is still cheap, record every finding in a
file, and close the loop so the same correction is never needed twice.

**Any agent can run this** — the spec author, the implementer, or a fresh one with no history. So it
is written to work from the artifacts alone: the spec bundle plus the code. Never assume the reviewer
remembers the conversation, and never assume the fixer does either.

A reviewer with no memory of writing the code catches more than one that has. If the user has a
choice, that is the one to prefer.

Write findings to `docs/specs/reviews/NNN-review.md`, numbered in sequence.

## What to review against

**The spec, first and above taste.** The tech spec is the agreed design. A deviation from it is a
finding, even when the code is arguably better — because the document is now wrong, and the next
reader will trust it.

Then, in order:

1. **Requirement coverage — start at the matrix, not the code.** Read `02-requirements.md`'s
   traceability table first. Every `Must` with no plan step, no component, or an empty verification
   cell is a finding before you have opened a single source file, and it is the cheapest finding you
   will ever raise. Then check the claims: a matrix row saying `done` whose acceptance criteria are not
   actually met is worse than an empty row.
2. **Spec conformance.** Does what was built match sections it claims to implement? Are all the
   components in the inventory present, with the responsibilities described?
3. **Correctness.** The rules and algorithms against their worked examples. The edge cases the spec
   listed. Off-by-one, rounding direction, null handling, ordering, tie-breaks.
4. **Requirement verification, FR and NFR.** See below — this is the part most often skipped, and the
   part where a confident "verified" is most often unearned.
5. **Boundary violations.** Dependencies pointing the wrong way. Framework or ORM types leaked into
   inner layers. The composition root's knowledge escaping into other places.
6. **Silent-wrongness risk.** For each change: if this were exactly backwards, what would tell us?
   Anything where the answer is "nothing" is a finding regardless of whether it is currently correct.
7. **Failure paths.** Every step of every flow — is the failure behaviour the spec specified actually
   implemented, or only the happy path? Every FR's stated failure behaviour, too.
8. **Verification gaps.** Steps marked verified whose verification does not prove what it claims.
   Any rule the tech spec's test strategy mandated a test for that has none. Negative cases never
   exercised. Tests that assert nothing, mirror the implementation, or cannot fail.
9. **Readability and balance.** Over-fragmentation and over-coupling both. Use the entry-point test
   from `senior-engineering`: read downwards from the entry point and see whether the decision is
   findable within one level.
10. **Leftovers.** Debug output, commented-out code, `TODO`s, scaffolding, unused imports, dead
    abstractions with no caller.

## Finding format

Every finding, in the file:

```markdown
### F-NNN — <short title>
Severity: blocker | major | minor | note
Category: requirement-gap | conformance | correctness | nfr-unverified |
          boundary | silent-risk | failure-path | verification |
          readability | leftover | spec-defect
Requirement: <FR/NFR id, where the finding is against one>
Location: <path>:<line>  (or "spec 02 §4.3" for a spec defect)
Spec ref: <section, if any>
Status: open | fixed | rejected | deferred

**What.** The defect, in one or two sentences.

**Why it matters.** The concrete consequence — the input, state or sequence
that produces a wrong result. If you cannot name one, downgrade to note.

**Suggested fix.** What to change. Not a rewrite of the whole area.

**Outcome.** Filled in by whoever acts on it: what was done, or the written
reason for rejecting it.
```

**Severity means something.** A blocker produces wrong data, loses money, or breaks a contract. A
major is a real defect on a reachable path. A minor is a defect on an unlikely path or a genuine
readability problem. A note is an observation with no defect behind it — keep these few, or they
train the reader to skim.

**No finding without a consequence.** "This could be cleaner" is not reviewable. Name the input that
breaks it, or the specific thing a reader misunderstands.

## Verifying the requirements

Take each requirement's `Verification` field and actually do it — **functional as well as
non-functional**. The point of this section is that an unverified requirement is reported as
unverified, never as met.

- **Functional requirements: exercise the acceptance criteria, do not read them.** Where a test
  covers a criterion, run it and name it. Where none does, a probe is the cheap answer — drive the
  flow against the real database, provider and bus, and check each criterion including the stated
  failure behaviour. Record the request and what actually came back. **"The implementation looks
  correct" is not verification of an FR** and must not be recorded as one; reading code and agreeing
  with it tells you nothing about behaviour.
- **Non-functional requirements: produce the number.** A probe that exercises the thing and prints a
  measurement, compared against the target — a loop that times a query, a script that captures emitted
  SQL and checks the plan, a serializer round-trip that measures payload size, a run at 10× volume to
  see whether the algorithm stays linear.
- **For either kind, say what the probe ran against.** A probe over fabricated data proves less than
  one over real data, and the difference belongs in the finding. Record the result; keep the probe out
  of the deliverable tree.
- **Structural check.** Where nothing above reaches the outcome, confirm the mechanism exists — the
  index, the timeout, the bound, the exclusion. Then write down that the mechanism was checked and
  the outcome was not. Reporting a structural check as if it were a measurement is the specific
  dishonesty this section exists to prevent.
- **Dedicated plan.** If the tech spec specified one and it was not run, that is an open finding, not
  a footnote.
- **Not verified.** Fine, if the entry says so and says what would be needed. A blank cell is not
  this.

A requirement whose criteria were checked and **missed** is a finding at the severity its consequence
deserves — for an NFR, read the `Consequence if missed` field it already carries rather than guessing.

## Spec defects are findings too

If the implementation is right and the spec is wrong, that is a `spec-defect` finding against the
document, located by section rather than by file. It is fixed by amending the spec — keeping the
superseded decision visible with the reason it changed — not by quietly letting the code diverge.

This is the most valuable category the review produces, because an approved spec that disagrees with
working code is worse than no spec: it actively misleads everyone who reads it next.

## The loop

1. **Reviewer writes findings to the file.** All of them, before any fixing starts. Reviewing and
   fixing in the same pass produces a shallow review, because the reviewer starts optimising for
   what is easy to fix.
2. **Present a summary**: counts by severity, and the blockers by name.
3. **Fixer works the findings in severity order**, filling in `Outcome` on each and setting `Status`.
4. **Rejections need a written reason**, in the file. "Deliberate because X" is a legitimate outcome
   and becomes a design-record entry — see below.
5. **Re-check only what changed.** Verify each fix against the finding that prompted it; do not
   re-review the untouched code.
6. **Close the review** with a line stating what remains open and why.

Findings live in the file, not in chat. A session ends; the file does not.

## Feed it forward

The point of recording feedback is that the correction is not needed a second time.

- **A rejected finding that was actually deliberate** belongs in the project's design record, with the
  failure it prevents. That is what stops the next reviewer — or the next agent — "fixing" it.
- **A finding that recurs across reviews** is not an implementation problem; it is a missing rule.
  Add it to the design record or the project instructions, so it is prevented rather than caught.
- **A whole category of finding appearing repeatedly** means the spec was too vague in that area.
  Note it, so the next project's tech spec covers it up front.

## Done when

- Every blocker and major is fixed or rejected with a written reason.
- Every fix has been verified against the finding that prompted it.
- Every `Must` requirement has been checked against its acceptance criteria, not just against the
  matrix saying `done`.
- Every requirement — FR and NFR — has a verification outcome recorded: the test that ran, the probe
  result and what it ran against, an explicit "mechanism checked, outcome not measured", or an
  explicit "not verified, needs X". No blanks.
- Every spec defect has been amended in the spec, not just in the code.
- Anything deliberate that looked wrong is recorded where the next reader will find it.
- The remaining open findings are listed with the reason each is still open.

## Reporting

Counts by severity, blockers by name, what was fixed, what was rejected and why, what remains open,
and any rule added to the design record. Short — the file holds the detail.

Never report a review as clean without saying what you actually checked. "No issues found" after
reading three files is not a review, and saying so is more useful than the reassurance.
