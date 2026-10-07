# Phase 2 — Requirements

**Goal:** the product spec's prose turned into numbered, testable requirements that the tech spec
satisfies, the plan implements, and the review checks. These are the files everything downstream cites.

**Hard rule: requirements are derived, not invented.** Every functional requirement traces to a
capability or journey in the product spec. If you are writing one with no origin there, either the
product spec is incomplete — go back and amend it — or you are inventing scope. Say which.

**Hard rule: no solution language.** "The system shall record the guest's nationality" is a
requirement. "Store nationality as a two-character column" is a tech-spec decision. If a requirement
names a table, framework or algorithm, it is in the wrong document.

Write to `docs/specs/02-requirements/` — or, for a later change, as requirement deltas (`changes.md`);
under the small track, to `docs/specs/requirements.md` (`small-track.md`).

## Contents
- The files
- IDs are permanent
- Functional requirements
- Non-functional requirements
- How requirements get verified
- The traceability matrix
- Done when
- Then stop

## The files

| File | Holds |
|---|---|
| `overview.md` | Counts by priority; the architecturally significant NFRs; NFR conflicts and how each was resolved; the security verification level chosen |
| `functional/<capability>.md` | The FRs for one capability (`C-NN`); split by sub-capability past 300 lines |
| `non-functional/<category>.md` | NFRs by category; small categories may share a file |
| `traceability.md` | The matrix; split by capability past 300 lines — each row still lives in exactly one place |

## IDs are permanent

`FR-001`, `NFR-001`, upward — always three digits, so a search for one id never matches another —
never renumbered and **never reused**. The tech spec, the plan and every
review cite these ids; recycling one silently repoints a citation at a different requirement. A
requirement that is dropped keeps its id and is marked `retired`, with the reason.

## Functional requirements

One block each. Priority is MoSCoW — `Must`, `Should`, `Could`, `Won't` — and `Must` is the set the plan
is obliged to cover. The statement is one testable sentence that states the rule; the acceptance
criteria are its key examples.

```markdown
### FR-014 — Free cancellation window
Source: C-03, J-02 (docs/specs/01-product/capabilities.md) · Priority: Must · Actor: Guest
Status: proposed | approved | retired

**Statement.** When a guest cancels a booking more than 24 hours before check-in, the system shall
refund the full amount.

**Preconditions.** The booking is paid and not yet checked in.

**Acceptance criteria.**
- AC-014.1 Given a paid booking with check-in in 30 hours, when the guest cancels, then the full
  amount is refunded and the booking is Cancelled.
- AC-014.2 Given a paid booking with check-in in 20 hours, when the guest cancels, then the
  cancellation fee applies (FR-015).

**Failure behaviour.** What happens when it cannot be satisfied: what the actor sees and what they can
do next. A requirement with no failure behaviour is half specified.

**Verification.** test | evaluation | probe | exercise | structural check | dedicated plan | not
verified — the mechanism that will show the acceptance criteria actually hold (see "How requirements
get verified").

**Known defect.** Only while one exists: how the current code fails this requirement, with its `F-` or
`P-` id. Removed when the fix ships.
```

**Writing the statement.** The EARS patterns below are a checklist, not a required syntax: a statement
that names its trigger or state and its response, and nothing else, passes whatever its wording. Use
them to ask whether there is exactly one trigger, whether it is an event or a state, and whether the
unwanted case has a statement of its own.

| Pattern | Form | Use for |
|---|---|---|
| Ubiquitous | The <system> shall <response>. | behaviour that always holds |
| Event-driven | When <trigger>, the <system> shall <response>. | a response to an event |
| State-driven | While <state>, the <system> shall <response>. | behaviour within a mode or state |
| Unwanted behaviour | If <unwanted condition>, then the <system> shall <response>. | failures, invalid input, abuse |
| Optional feature | Where <feature is included>, the <system> shall <response>. | variants and configuration |
| Complex | While <state>, when <trigger>, the <system> shall <response>. | combinations |

More than three conditions in one statement means the rule is a decision table — put the table in the
requirement instead of a longer sentence.

What makes one testable:

- **It names an observable outcome**, not an internal state. "The order is recorded as failed with a
  reason" is checkable; "the system handles the error correctly" is not.
- **One requirement, one behaviour.** If the statement needs "and", it is probably two.
- **No adjectives doing load-bearing work.** "Quickly", "reliably", "properly", "user-friendly" all
  belong in an NFR with a number, or nowhere.
- **The negative case is stated** — usually as an unwanted-behaviour statement — not left to the
  implementer's judgement.

**Acceptance criteria are examples, not an enumeration.** One to three per requirement: the boundary,
the failure case, and the worked example where one exists. The statement fixes the rule, the examples
fix its edges, and the tests enumerate the cases — a spec that lists every state duplicates the test
suite and drifts from it. Given/When/Then is one format; `input → outcome` in a bullet, or a table row,
serves as well. Needing more than three means the rule is a decision table, or two requirements.

**Requirements on outputs that vary.** Some behaviour is judged over many cases, not case by case —
search relevance, ranking, recommendations, classification, extraction from documents, text generated
by a language model. No single correct output exists per input, so the target is a rate over a named
evaluation set:

> When an invoice is uploaded, the system shall extract its total and due date — target: ≥ 98% of
> fields correct over the 300 invoices in `<path to the evaluation set>`, against hand-checked values.

- **The evaluation set is part of the spec**: versioned in the repository, with its size, how it was
  built, and who judged the expected outcomes.
- **The deterministic parts around the varying core stay ordinary requirements** — what happens when
  nothing is found, the limits on input, that every reference in the output points at something real.
- **The acceptance criteria are the threshold** plus two or three illustrative cases from the set, and
  the verification is `evaluation`.

## Non-functional requirements

Work the categories below. For each, either write requirements or write "not applicable" with a
reason — silence reads as oversight and is the most common way an NFR is discovered in production.

Performance · Scalability · Availability and reliability · Security · Privacy and compliance ·
Observability · Maintainability · Usability and accessibility · Internationalisation · Compatibility
and portability · Cost — and any quality the product needs that this list does not name.

```markdown
### NFR-NNN — <category>: <short title>
Source: product spec file and item, or the constraint it comes from
Priority: Must | Should | Could · Status: proposed | approved | retired

**Statement.** The quality required, in one sentence.

**Target.** As a scenario: under <environment>, when <stimulus> from <source> reaches <part of the
system>, it shall <response>, measured as <number, unit, condition>.

**Measurement.** How it is measured, with what, observed where.

**Verification.** test | evaluation | probe | exercise | structural check | dedicated plan | not
verified — see below.

**Consequence if missed.** What actually goes wrong for whom. If you cannot name one, this is not a
requirement; delete it.
```

**An NFR without a number and a measurement method is not an NFR.** It is a wish, and it will be declared
met by whoever is asked. Convert or delete:

| Wish | Requirement |
|---|---|
| "Search must be fast" | p95 response ≤ 300 ms at 50 req/s sustained, measured at the API boundary |
| "Must scale" | 10× current volume — 500 orders/day — with no change to the deployment topology |
| "Must be highly available" | 99.5% monthly, excluding announced maintenance; degrades to read-only rather than erroring |
| "Must be secure" | Meets the chosen OWASP ASVS level for the listed requirement ids; no credential, token or payment field appears in any log or client response, verified by tests over captured logs and every response contract |
| "Must be maintainable" | Every pricing rule has an automated test; a new product type needs no change to existing rule classes |

**Security gets a level, not an adjective.** Choose the OWASP ASVS verification level with the user —
the middle level suits most applications that hold personal data or move money — and cite the ASVS
requirement ids the threat model's mitigations rely on, alongside the product's own security
requirements.

**Name the conflicts.** NFRs contradict each other — latency against consistency, auditability against
data minimisation, cost against redundancy. A pair that cannot both hold is a decision, not an
oversight: record both ids, which one wins, and what the loser is relaxed to. Discovering that trade
during implementation means rebuilding.

**Flag the architecturally significant ones.** Usually two to five NFRs actually drive the stack and the
shape of the system; the rest are satisfied by ordinary care. Mark them in `overview.md`, because the
stack ADRs have to cite them by id — that is what stops the stack being chosen on preference.

## How requirements get verified

**Every requirement carries a `Verification` field — functional and non-functional alike.** A
requirement nobody can show is met is indistinguishable from one that is not. The mechanisms, strongest
evidence first:

1. **Automated test — the best answer wherever the project has a place for one.** Permanent, runs again
   next month, fails loudly when someone breaks the rule. Unit tests for pure logic; integration tests
   with Testcontainers wherever the behaviour crosses an external dependency; the four test lenses and
   the flow's other risks from senior-engineering's `testing.md` for significant flows; mutation testing
   on the core rules.
2. **Evaluation — for an output judged over many cases.** A versioned dataset of inputs with expected
   outcomes, a scoring method, and the requirement's threshold; automated and re-run like a test. Record
   the score with the dataset version and the model or configuration it ran against. A score below the
   threshold fails, like a red test.
3. **Probe — a throwaway project or script whose only job is to exercise the thing and report.** Use it
   when there is no suite to add to, or when the answer is a measurement rather than a pass/fail.
   - **For an FR:** drive the flow end to end and check the acceptance criteria against the real
     database, the real provider, the real bus — that the row is actually written, the message actually
     published, the endpoint actually returns the documented shape.
   - **For an NFR:** produce the number. Query timing and emitted plans, index use, behaviour at 10×
     volume, payload size, cold-start time, bound enforcement.
   - **The probe is disposable; its output is not.** The result is recorded once, with the step that
     ran it (`plan.md`), with what it ran against — a probe against fabricated data proves less than
     one against real data. Keep probes out of the deliverable tree.
4. **Exercise — call the running system and check the result by hand.** Weaker than a probe only
   because nothing captures it for next time; record the request and the response.
5. **Structural check — where nothing above can reach the outcome, confirm the mechanism exists.** The
   index is present, the timeout configured, the bound enforced. Record that the *mechanism* was
   checked and the *outcome* was not. **These are not the same claim and must never be reported as if
   they were.** For an FR it is almost always a sign the requirement is not testable as written.
6. **Dedicated verification plan — for a requirement important enough that none of the above is honest
   enough.** Real load profile, soak, failover drill, penetration test. Reserve it for the
   architecturally significant ones.
7. **Not verified — allowed, but only out loud.** An explicit entry saying so, why, and what would be
   needed. Never a silent gap.

**An FR whose only verification is "the code looks right" is unverified.** Reading an implementation and
agreeing with it is not evidence about behaviour.

## The traceability matrix

`traceability.md`, initialised here with every requirement; the tech spec and the plan fill in their
columns, and nothing changes it during implementation. From CH-002 on, each change keeps the same table
for the items it adds or modifies in its own delta file, and merges those rows here at close.

```markdown
| ID | Requirement | Priority | Tech spec | Components | Plan step |
|---|---|---|---|---|---|
| FR-001 | Guest can book a stay | Must | docs/specs/03-tech/flows/FL-01-book-stay.md | BookingService | CH-001/S-04 |
| NFR-003 | p95 ≤ 300 ms @ 50 rps | Must | docs/specs/03-tech/performance.md | search query, index IX_… | CH-001/S-09 |
```

The plan-step cell links to everything after planning — the step's status, its result, and by its id
the change that built it. It holds the step id (`CH-NNN/S-NN`, or a small change's
`YYYY-MM-DD-<slug>`), `existing` for code that predates the specs, `retired`, or nothing yet.

What the matrix is *for* — read it, do not just maintain it:

- **A `Must` with no plan step is unimplemented.** The single most valuable thing this table tells you,
  and it is invisible in prose.
- **A requirement with no component is unassigned** — nothing owns it.
- **A component satisfying no requirement is scope creep**, and worth asking about.
- **A plan step citing no requirement is work nobody asked for.**

Each fact lives in one place. Copies drift, and a drifted coverage matrix is worse than none because it
reports coverage that does not exist. So nothing is recorded twice: the requirement holds its lifecycle
status and its verification *mechanism*; the matrix holds where it is designed and planned; the progress
table holds the step's status; the verification *result* is recorded once, with the step (`plan.md`).
A requirement whose step is done but whose result does not show its criteria met is unproven, whatever
the code looks like.

## Done when

- Every product-spec capability maps to at least one FR, and every FR traces back to one.
- Every FR has a testable statement, one to three acceptance criteria, a stated failure behaviour, and
  a verification mechanism.
- Every NFR has a target number, a measurement method, a verification approach and a named consequence.
- The security level is chosen and the applicable security requirements are listed.
- Every NFR category is either populated or explicitly marked not applicable.
- NFR conflicts are named with a decided winner, and the architecturally significant NFRs are flagged.
- The matrix lists every id, with downstream columns empty and ready.
- No `TBD`, no unmeasurable NFR, no unresolved `Q-` citation in an approved file.

## Then stop

Present the FR and NFR counts by priority, the conflicts and how they were resolved, the
architecturally significant NFRs, the `assumed` entries and every open question. Get approval before
the tech spec — it is built to satisfy these files, so an unapproved requirement set produces a tech
spec that has to be redone.
