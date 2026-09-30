# Phase 3, part 2 — Technical spec: behaviour and assurance

Part 1 (`tech-spec-structure.md`) fixed what exists. This part fixes how it behaves — flows, rules,
cross-cutting concerns — and how you will know it works: performance, tests, security. The same hard
rules apply: no product decisions, no new requirements, every element cites the ids it serves.

## Contents
- The files
- Step 7 — Flows
- Step 8 — Rules and algorithms
- Step 9 — Cross-cutting concerns
- Step 10 — Performance, and how every NFR is met
- Step 11 — Test strategy
- Step 12 — Security
- Decisions and open questions
- Quality bars
- Pre-mortem, then stop

## The files

| File | Holds |
|---|---|
| `flows/FL-NN-<slug>.md` | One significant use case per file |
| `rules/RL-NN-<slug>.md` | One non-obvious rule or algorithm per file, with its worked example |
| `cross-cutting.md` | The cross-cutting decisions; split by concern past 300 lines |
| `performance.md` | The NFR mechanism table and the performance work |
| `testing.md` | The test strategy |
| `security.md` | Threat model, data classification, controls |

## Step 7 — Flows

For every significant use case, a numbered walkthrough. This is where correctness is actually decided.

**Each flow names the FR ids it implements, and those requirements' acceptance criteria are the flow's
success test** — do not restate them in different words, or the two will drift and nobody will know
which is authoritative. A Mermaid `sequenceDiagram` helps where more than two parts interact.

Per step: what is called, what it returns, what is written, what is published, and **what happens if
this step fails**. Then, for the flow as a whole:

- **Transaction boundaries** — what commits together, and what is deliberately outside the transaction.
- **Ordering that matters**, and why. Note anything that must be persisted before a remote call, or
  published only after a commit.
- **Idempotency** — what makes a repeat of this flow safe, and what the repeated caller receives.
- **Concurrency** — the contended resources in this flow and how each is arbitrated: unique constraint,
  concurrency token, lock, atomic update, single-writer queue.
- **The failure matrix**: for each step, the failure, the resulting state, whether it is retryable, and
  whether it needs compensating.
- **What a reader of the stored record can tell afterwards** about how far the flow got. If the answer is
  "nothing", add it.

A flow with only a happy path is not specified. The failure behaviour will otherwise be invented during
implementation, under time pressure, by whoever hits it first.

## Step 8 — Rules and algorithms

Any non-obvious computation, ordering, matching or selection logic, written out precisely.

- **The formula or procedure**, unambiguously.
- **A worked example with real numbers**, and the expected output. This is the single most useful thing
  in the spec, and it is what an implementer will check their work against.
- **The edge cases**: empty, zero, negative, one element, ties, absent input, maximum, overflow, rounding
  direction.
- **Rounding, precision and units** wherever money, time or measurement is involved. State the rounding
  direction and where it is applied — this is a decision, not a detail.
- **Ordering rules**, where output order is part of the contract, and what the tie-break is.
- **Time and time zone**: what is stored, in what zone, and where conversion happens.
- **Complexity at the stated scale**, where the input can grow — so the review can check the
  implementation against it.

If a rule is easy to get wrong in a way that still looks plausible, say so explicitly and give the
wrong-but-plausible version alongside the right one.

## Step 9 — Cross-cutting concerns

Each of these, decided once and written down: authentication and authorization model; configuration and
secrets; logging, and what must never be logged; metrics, tracing and health; the error-handling
convention; localization and text; caching and invalidation; background work and scheduling; file and
blob handling. Where one does not apply, say "not applicable" rather than omitting it — silence reads as
oversight.

## Step 10 — Performance, and how every NFR is met

Sized from the requirements' own numbers, not from imagination. **Do not restate an NFR's target** —
cite the id and say what makes it hold. One row per NFR, all of them, including those met by doing
nothing special:

```markdown
| NFR | Target (from requirements) | Mechanism here | Verification | Residual risk |
|---|---|---|---|---|
| NFR-003 | p95 ≤ 300 ms @ 50 rps | covering index IX_…, no N+1, bounded page | load test in CI (docs/specs/03-tech/testing.md) | cold cache untested |
```

- **A mechanism of "n/a" or "the framework handles it" is a gap**, not an entry. Say which framework
  behaviour, and what happens when it does not apply.
- **`Verification` must match what phase 2 chose.** If a target turns out to need a dedicated plan, that
  is a phase-2 amendment, not a quiet downgrade here.
- **Where a probe or load test is the verification, specify it**: what it measures, what it runs
  against, and the number that counts as a pass. The probe is throwaway; this specification is what
  makes its result reproducible.

Then the performance work itself:

- **Expected load** and the resulting hot paths.
- **The specific optimizations chosen**, each with the reason and the cost it accepts — using the stack
  playbook's current practice for the pinned versions.
- **What was deliberately not optimized**, and the threshold at which that should be revisited.
- **The known pathological cases** — the query that would table-scan, the N+1, the unbounded result set —
  and what prevents them.

Premature optimization and unexamined slowness are both failures. Name which risk you took.

## Step 11 — Test strategy

A decision, recorded, not a default — built on senior-engineering's `testing.md`.

**One class is not optional: pure logic carrying a rule that was hard to get right.** Money and rounding
arithmetic, tax and commission splits, ordering and tie-breaks, parsing and code mapping,
state-transition guards, anything whose worked example in Step 8 took effort to get correct, and
anything an area record describes as having been wrong before. These have no I/O, so a test is cheap,
and they are exactly the code where a regression is both most likely and least visible. If this project
has such logic and no test covering it, that is a gap to name, not a preference.

**Challenge each significant flow from the four lenses** — business rules, technical correctness,
performance and concurrency, security — and write down, per flow, which lenses apply and what each
test tries to break. A lens skipped for a flow is skipped with a reason.

```markdown
| Level | What is covered here | What is deliberately not | Command |
|---|---|---|---|
| Unit | domain rules, rules/RL-*, value objects | framework wiring | |
| Integration (Testcontainers) | every flow that writes data or publishes; concurrency and idempotency tests | | |
| Contract | outbound providers whose shape can drift | | |
| Architecture | the layering ADR's rules | | |
| Mutation | the domain core, with the break threshold | adapters, UI glue | |
| Load / benchmark | the architecturally significant NFRs | | |
| Smoke | the deployed thing answers and its dependencies resolve | | |
```

What each level is actually for:

- **Unit** — pure logic in isolation: fast, deterministic, no database, network or clock. The mandated
  class lives here, and the Step 8 worked examples become its test data directly.
- **Integration** — the real path through real dependencies, on Testcontainers. Slower, so choose the
  paths where money moves or data is written rather than aiming at coverage.
- **Contract** — that an external service still returns the shape you mapped. Worth its cost the moment
  a provider can change independently of your release, because that drift is silent: a field added
  upstream compiles fine and arrives unconverted.
- **Characterization** — locks in current behaviour before a refactor, so the diff proves equivalence.
- **Property-based** — for invariants rather than examples: a round-trip that must return its input, a
  sum that must equal its parts. One property replaces a table of cases and finds the input you would
  not have thought of.
- **Mutation** — proves the unit and integration tests on the core can fail when the code is wrong.
- **Smoke** — the deployed thing answers and its dependencies resolve.

- **Integration infrastructure**: which Testcontainers images, pinned to the production versions, the
  reset strategy between tests, and what CI needs (Docker, Linux runners).
- **Mutation testing**: which modules, which tool, the break threshold, and when it runs.
- **Which requirement ids are covered by a test**, and which rely on a probe, a structural check or
  nothing — this is the `Verification` column of the matrix, and the strategy has to agree with it.
- **The exact verification command**, so an implementer and a reviewer run the same thing.
- **If the project will have no automated tests, say so and say what replaces them.** "No tests" with
  nothing named in its place means nothing is verified, and every rule in this spec is protected by
  prose alone.
- **What is deliberately not tested, and why.** Configuration wiring, framework behaviour, third-party
  libraries and trivial accessors are usually right to leave alone; saying so stops the question
  recurring at review.

## Step 12 — Security

Security is designed here, not bolted on at review. Build on senior-engineering's `security.md`.

**Data classification**: every data class the system handles — public, internal, confidential, secret,
personal — where each is stored, who may read it, and what must never be returned to a client or
written to a log.

**Threat model**, one section per trust boundary:

```markdown
### Boundary: <e.g. public API → application>
Assets: <data classes> · Actors: <roles, anonymous callers, other services> · Entry points: <endpoints, queues>

| ID | Element | STRIDE | Threat | Likelihood × impact | Mitigation | Requirement / ASVS | Test |
|---|---|---|---|---|---|---|---|
| TH-01 | booking endpoint | E | guest reads another guest's booking by id | high × high | object-level ownership check | NFR-007 | authz matrix test |

Accepted risks: <each with an owner and a revisit date>
```

- **The controls**: authentication, authorization per operation and per object, input validation,
  secrets handling and credential lifetime, encryption at rest and in transit, rate and size limits,
  outbound-call restrictions, security logging.
- **Each mitigation maps to a requirement id and a test** — a mitigation with neither is a hope.
- **Keep it current**: a change that adds a trust boundary or a data class updates the model.

## Decisions and open questions

- **Decisions** are ADRs. List the ones this spec relies on — id, title, status — and link them. A
  decision still `proposed` blocks the parts of the spec that depend on it; mark those parts.
- **Open questions** are `Q-` entries, cited where they apply.

## Quality bars

Before declaring the tech spec done:

| Check | Requirement |
|---|---|
| Types | Every field has a concrete type, precision and nullability |
| Indexes | Each names the query it serves |
| Flows | Each has a failure path per step, and its idempotency and concurrency decided |
| Rules | Each has a worked example with real numbers |
| Components | Every responsibility is one sentence with no "and" |
| Domain | Aggregates are rich; every plain-CRUD classification is justified |
| Versions | Every dependency pinned; the stack playbook written |
| Nulls | Every nullable field states what null means |
| Vagueness | No `TBD`, no `etc.`, no "as appropriate" |
| Vocabulary | Terms match the glossary exactly |
| Coverage | Every `Must` requirement is served by at least one component or flow |
| NFRs | Every one has a mechanism row and a verification approach |
| Tests | Every hard-won rule in Step 8 is covered by a test, or the gap is named; every significant flow has its lenses |
| Security | Every trust boundary has a threat table; every mitigation has a requirement and a test |
| Decisions | Every significant decision is an ADR; none is decided in prose alone |
| Citations | No component with an empty `Satisfies`, no flow without an FR id |
| Matrix | The `Tech spec` and `Components` columns are filled in |
| Files | Every file within budget, with its header, listed in the manifest |

Then the handoff test: **list what a competent stranger would still have to ask you.** That list is
your remaining work. Empty it, or record each item as a `Q-` entry.

## Pre-mortem, then stop

Run the pre-mortem (`discovery.md`) and fold its results in. Then present the stack ADRs, the
architecture, the plain-CRUD classifications, the threat model's accepted risks, the `assumed` entries,
the open questions and any proposals. Get approval before writing the plan. The plan makes no new
decisions, so an unapproved tech spec produces a plan that has to be rewritten.
