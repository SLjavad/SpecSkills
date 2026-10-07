# Phase 6 — Review and feedback

**Goal:** find what the implementation got wrong while it is still cheap, record every finding in a
file, and close the loop so the same correction is never needed twice.

**Any agent can run this** — the spec author, the implementer, or a fresh one with no history. So it is
written to work from the artifacts alone: the living specs, the change folder, and the code. Never assume
the reviewer remembers the conversation, and never assume the fixer does either. A reviewer with no
memory of writing the code catches more than one that has; if the user has a choice, prefer that one.
In multi-agent mode it runs in the lead role, and its blocking findings reach the coder as a fix step
(`multi-agent.md`, the protocol's "Rounds and findings").

Write the review to one file, `docs/changes/CH-NNN-<slug>/reviews/R-NN.md`: a short summary first —
counts by severity, blockers by name, what was checked — then the findings, grouped by lens. Only past
the 300-line cap does it split into `reviews/R-NN/`, by lens group, with the summary in `README.md`.
**A review with no findings writes no file**: one line on the change's status in `proposal.md` records
the date and what was checked. A task's review in multi-agent mode uses the same finding format, and is
written only when its coder must act; this phase reviews the whole change before it closes.

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

1. **Requirement coverage — start at the matrix, not the code.** Every `Must` with no plan step or no
   component is a finding before you have opened a single source file — the cheapest finding you will
   ever raise. Then follow each plan step to its result — the step's *Result*, or in multi-agent mode
   the task's report — and check the claim: a step marked `done` whose acceptance criteria are not
   actually met is worse than one still open.
2. **Spec conformance.** Does what was built match the files it claims to implement? Are all the
   inventory's components present, with the responsibilities described?
3. **Requirement verification, FR and NFR** — see below. The part most often skipped, and the part where
   a confident "verified" is most often unearned.
4. **Failure paths.** Every step of every flow — is the failure behaviour the spec specified actually
   implemented, or only the happy path? Every FR's stated failure behaviour, too.
5. **Silent-wrongness risk** — `design.md`'s question for each change: if this were exactly backwards,
   what would tell us? "Nothing" is a finding, whether or not the code is currently correct.
6. **The threat model.** Every mitigation implemented and tested; no trust boundary or data class the
   model does not know about.
7. **Every code-quality lens in senior-engineering's `review.md`** — correctness against the spec's
   worked examples and edge cases, design, domain, dependencies, efficiency at the spec's stated scale,
   the security audit (always), tests, readability and leftovers — plus the architecture tests an ADR
   names.
8. **The documents tell the truth.** The change deltas, ADRs and area records match the code, so the
    merge at close (`changes.md`) will leave the living specs correct. A mismatch is a `spec-defect`
    finding, or `conformance` where the code is what is wrong.

The order above is the minimum; add any lens the change calls for — a data migration, accessibility,
operability, compatibility with existing clients.

## Finding format

Every finding — in this phase's review and in a multi-agent task's review alike — uses the one finding
format in senior-engineering's `references/review.md` ("Writing findings"), with this phase's lenses:
requirement-gap, conformance, unverified, silent-risk, failure-path and spec-defect. `F-` ids are
scoped to the change and allocated in one sequence across its task reviews and phase-6 reviews — by the
lead in multi-agent mode, by the reviewer otherwise. Cite them as `CH-007/F-12`.

## Verifying the requirements

Take each requirement's `Verification` field and actually do it, by its method in senior-engineering's
`testing.md` — **functional as well as non-functional**. An unverified requirement is reported as
unverified, never as met.

- **Functional requirements: exercise the acceptance criteria, do not read them** — run the test that
  covers each and name it, or probe it, the stated failure behaviour included. **"The implementation
  looks correct" is not verification of an FR** and must not be recorded as one.
- **Non-functional requirements: produce the number** and compare it with the target.
- **Record what each ran against.** A structural check is recorded as one, never as a measurement; a
  dedicated plan the tech spec specified and nobody ran is an open finding; a blank is never "not
  verified".

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
goes to the proposal register (`discovery.md`) in the one proposal format — with its evidence, expected
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
- Every `Must` requirement has been checked against its acceptance criteria, not just against its step
  being `done`.
- Every requirement — FR and NFR — has its verification outcome recorded once, in its step's result
  (one agent) or report (multi-agent): the test that ran, the probe result and what it ran against, an
  explicit "mechanism checked, outcome not measured", or an explicit "not verified, needs X". No blanks;
  where one falls short, the gap is a finding here.
- The security lens ran and its critical and high findings are closed.
- Every spec defect is amended in the spec, not just in the code.
- Anything deliberate that looked wrong is recorded where the next reader will find it.
- The remaining open findings are listed with the reason each is still open.

## Reporting

Counts by severity, blockers by name, what was fixed, what was rejected and why, what remains open, the
proposals raised, and any rule added to a record. Short — the files hold the detail.

Never report a review as clean without saying what you actually checked. "No issues found" after reading
three files is not a review, and saying so is more useful than the reassurance.
