# Phase 2 — Requirements

**Goal:** the product spec's prose turned into numbered, testable requirements that the tech spec
satisfies, the plan implements, and the review checks. This is the document everything downstream
cites.

**Hard rule: requirements are derived, not invented.** Every functional requirement traces to a
capability or journey in the product spec. If you are writing one with no origin there, either the
product spec is incomplete — go back and amend it — or you are inventing scope. Say which.

**Hard rule: no solution language.** "The system shall record the guest's nationality" is a
requirement. "Store nationality as a two-character column" is a tech-spec decision. If a requirement
names a table, framework or algorithm, it is in the wrong document.

Write to `docs/specs/02-requirements.md`.

## IDs are permanent

`FR-01`, `NFR-01`, upward, never renumbered and **never reused**. The tech spec, the plan and every
review cite these ids; recycling one silently repoints a citation at a different requirement. A
requirement that is dropped keeps its id and is marked `Retired`, with the reason.

## Functional requirements

One block each. Priority is MoSCoW: `Must`, `Should`, `Could`, `Won't` — and `Must` is the set the plan
is obliged to cover.

```markdown
### FR-NN — <short title>
Source: product spec §<n> — <capability or journey>
Priority: Must | Should | Could | Won't
Actor: <role from the product spec>
Status: proposed | approved | retired

**Statement.** The system shall <observable behaviour>.

**Preconditions.** What must be true before this applies.

**Acceptance criteria.** Observable, checkable, one per line — Given/When/Then where it helps.

**Failure behaviour.** What happens when it cannot be satisfied: what the actor sees and what
they can do next. A requirement with no failure behaviour is half specified.

**Verification.** test | probe | integration | manual | not verified — see "How requirements
get verified". Name the mechanism that will show the acceptance criteria actually hold.
```

What makes one testable:

- **It names an observable outcome**, not an internal state. "The order is recorded as failed with a
  reason" is checkable; "the system handles the error correctly" is not.
- **One requirement, one behaviour.** If the statement needs "and", it is probably two.
- **No adjectives doing load-bearing work.** "Quickly", "reliably", "properly", "user-friendly" all
  belong in an NFR with a number, or nowhere.
- **The negative case is stated**, not left to the implementer's judgement.

## Non-functional requirements

Work the categories below. For each, either write requirements or write "not applicable" with a
reason — silence reads as oversight and is the most common way an NFR is discovered in production.

Performance · Scalability · Availability and reliability · Security · Privacy and compliance ·
Observability · Maintainability · Usability and accessibility · Internationalisation ·
Compatibility and portability · Cost

```markdown
### NFR-NN — <category>: <short title>
Source: product spec §<n>, or the constraint it comes from
Priority: Must | Should | Could
Status: proposed | approved | retired

**Statement.** The quality required, in one sentence.

**Target.** A number, a unit, and the condition it holds under.

**Measurement.** How it is measured, with what, observed where.

**Verification.** probe | structural check | dedicated plan | not verified — see below.

**Consequence if missed.** What actually goes wrong for whom. If you cannot name one, this is
not a requirement; delete it.
```

**An NFR without a number and a measurement method is not an NFR.** It is a wish, and it will be
declared met by whoever is asked. Convert or delete:

| Wish | Requirement |
|---|---|
| "Search must be fast" | p95 response ≤ 300 ms at 50 req/s sustained, measured at the API boundary |
| "Must scale" | 10× current volume — 500 orders/day — with no change to the deployment topology |
| "Must be highly available" | 99.5% monthly, excluding announced maintenance; degrades to read-only rather than erroring |
| "Must be secure" | No credential, token or payment field appears in any log or client response; verified by grep over a captured log and over every response contract |
| "Must be maintainable" | Every pricing rule has an automated test; a new product type needs no change to existing rule classes |

**Name the conflicts.** NFRs contradict each other — latency against consistency, auditability
against data minimisation, cost against redundancy. A pair that cannot both hold is a decision, not an
oversight: record both ids, which one wins, and what the loser is relaxed to. Discovering that trade
during implementation means rebuilding.

**Flag the architecturally significant ones.** Usually two to five NFRs actually drive the stack and
the shape of the system; the rest are satisfied by ordinary care. Mark them, because the tech spec's
stack decision has to cite them by id — that is what stops the stack being chosen on preference.

## How requirements get verified

**Every requirement carries a `Verification` field — functional and non-functional alike.** A
requirement nobody can show is met is indistinguishable from one that is not.

The mechanisms, strongest evidence first:

1. **Automated test — the best answer wherever the project has a place to put one.** Permanent, runs
   again next month, and fails loudly when someone breaks the rule. This is the natural home for an
   FR's acceptance criteria and for any pure logic: arithmetic, parsing, mapping, ordering, state
   transitions.
2. **Probe — a throwaway project or script whose only job is to exercise the thing and report what
   happened.** Use it when there is no test suite to add to, when the behaviour only appears against a
   real dependency, or when the answer is a measurement rather than a pass/fail.
   - **For an FR:** drive the flow end to end and check the acceptance criteria against the real
     database, the real provider, the real bus. This is how you verify a requirement that a unit test
     cannot reach — that the row is actually written, that the message is actually published, that the
     endpoint actually returns the documented shape.
   - **For an NFR:** produce the number. Query timing and emitted plans, index use, behaviour at 10×
     volume, payload size, cold-start time, bound enforcement.
   - **The probe is disposable; its output is not.** The result — the number, or the observed
     behaviour — goes into the requirements document and the review. Keep probes out of the
     deliverable tree, and say what they ran against: a probe against fabricated data proves less than
     one against real data, and the difference belongs in the record.
3. **Integration exercise — call the running system and check the result by hand.** Weaker than a
   probe only because nothing captures it for next time; record the request and the response you got.
4. **Structural check — where nothing above can reach the outcome, confirm the mechanism exists.** The
   index is present, the timeout is configured, the retry policy is attached, the secret is excluded
   from the log, the result set is bounded. Record that the *mechanism* was checked and the *outcome*
   was not. **These are not the same claim and must never be reported as if they were.** Mostly an NFR
   answer; for an FR it is almost always a sign the requirement is not testable as written.
5. **Dedicated verification plan — for a requirement important enough that none of the above is
   honest enough.** Real load profile, soak, failover drill, penetration test. The tech spec states
   the tool, the profile and the pass threshold; the plan carries steps for it. Reserve this for the
   architecturally significant ones; specifying it for every requirement is how the whole practice
   gets abandoned.
6. **Not verified — allowed, but only out loud.** An explicit entry saying so, why, and what would be
   needed. Never a silent gap, and never a requirement that reads as satisfied because nobody checked.

**An FR whose only verification is "the code looks right" is unverified.** Reading an implementation
and agreeing with it is not evidence about behaviour — that is what step 2 costs almost nothing to
get.

## The traceability matrix

The last section of this document, and the reason the ids exist. Initialise it here with every
requirement; the tech spec, the plan and each review fill in and update their columns.

```markdown
## Traceability
| ID | Requirement | Priority | Tech spec § | Components | Plan steps | Verification | Status |
|---|---|---|---|---|---|---|---|
| FR-01 | Guest can book a stay | Must | 03 §7.1 | BookingService, … | 12, 13 | test: … | done |
| NFR-03 | p95 ≤ 300 ms @ 50 rps | Must | 03 §10 | search query, index IX_… | 8 | probe: 214 ms | done |
```

What the matrix is *for* — read it, do not just maintain it:

- **A `Must` with no plan step is unimplemented.** That is the single most valuable thing this table
  tells you, and it is invisible in prose.
- **A requirement with no component is unassigned** — nothing owns it.
- **An NFR with an empty verification cell is unproven**, whatever the code looks like.
- **A component satisfying no requirement is scope creep**, and worth asking about.
- **A plan step citing no requirement is work nobody asked for.**

Keep it in one place. Copies drift, and a drifted coverage matrix is worse than none because it
reports coverage that does not exist.

## Done when

- Every product-spec capability maps to at least one FR, and every FR traces back to one.
- Every FR has acceptance criteria, a stated failure behaviour, and a verification mechanism.
- Every NFR has a target number, a measurement method, a verification approach and a named
  consequence.
- No requirement of any kind has an empty `Verification` field.
- Every NFR category is either populated or explicitly marked not applicable.
- NFR conflicts are named with a decided winner.
- Architecturally significant NFRs are flagged for the stack decision.
- The matrix lists every id, with downstream columns empty and ready.
- No `TBD`, no unmeasurable NFR, no requirement whose acceptance criteria you could not check.

## Then stop

Present the FR and NFR counts by priority, the conflicts and how they were resolved, the
architecturally significant NFRs, and every open question. Get approval before the tech spec — it is
built to satisfy this document, so an unapproved requirement set produces a tech spec that has to be
redone.
