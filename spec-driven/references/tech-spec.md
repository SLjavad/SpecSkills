# Phase 3 — Technical spec

**Goal:** the roadmap. Detailed enough that an implementer creates the right classes, tables, types
and flows without asking you anything, and specific enough that two implementers working from it
independently would produce substantially the same system.

This is the longest document in the bundle and the one that earns the method. Vagueness here becomes
improvisation later.

**Hard rule: no product decisions and no new requirements.** If writing this surfaces a question about
what the product should do, go back to phase 1. If it surfaces a requirement nobody wrote down, add it
in phase 2. Neither gets settled here, and neither gets buried in a design paragraph.

**Hard rule: this document satisfies `02-requirements.md`, so it cites it.** Every component, flow and
performance decision names the `FR-`/`NFR-` ids it serves, and you fill in the `Tech spec §` and
`Components` columns of that document's traceability matrix as you go. A design element serving no
requirement is either scope creep or a missing requirement — resolve which, do not leave it.

Write to `docs/specs/03-tech-spec.md`.

## Step 1 — Choose the stack, with the user

The stack is **not** assumed and **not** inherited from whatever you saw last. It is the first
decision of this phase, and it is the user's to make. Discuss it, then record it.

**Start from the architecturally significant NFRs**, which phase 2 flagged for exactly this. The stack
decision must cite them by id: if nothing in `02-requirements.md` drove the choice, it was made on
preference, and saying so honestly is better than dressing it up.

Bring the user a recommendation with reasons and real alternatives. What to weigh:

- **What the team already runs.** An unfamiliar-but-better stack is usually worse. Ask what they
  operate today, and what they are willing to operate.
- **Fit to the problem.** Heavy concurrency, heavy data, heavy UI, scheduled batch, real-time — these
  point different ways.
- **The scale numbers from the product spec.** Do not choose for a scale nobody stated.
- **Obligatory integrations.** An SDK that exists for one ecosystem and not another decides more than
  taste does.
- **Deployment and operational reality.** Where does this run, who watches it, what does the team
  already have for logs, metrics, CI, secrets.
- **Persistence shape.** Relational, document, key-value, search, time-series, or several — driven by
  the access patterns, not by preference.
- **Team size and lifespan.** A one-person tool and a system a team maintains for five years justify
  different structure.

Then record it as a decision, not a preference:

```markdown
## 1. Stack decision
| Concern | Choice | Version | Why |
|---|---|---|---|
| Language / runtime | | | |
| Framework | | | |
| Persistence | | | |
| Migrations | | | |
| Messaging / jobs | | | |
| Testing | | | |
| Build / CI | | | |
| Hosting / runtime target | | | |
| Observability | | | |

Driven by: <NFR ids that made this the answer>.
Rejected: <option> — <why not>.
Constraints this imposes: <what the choice now forces or forbids>.
```

**Pin versions.** "Latest" is not reproducible and will not be the same next month.

Once chosen, **write the rest of this document concretely in that ecosystem** — its real type names,
its real project layout, its idioms. Generic pseudo-guidance is what this phase exists to avoid.

## Step 2 — Architecture

- **Style, named and justified**: layered / clean / hexagonal / modular monolith / services / vertical
  slices. State why it fits *this* project's size and team, not why it is good in general.
- **Module boundaries and the dependency direction.** List every module and what it may depend on.
  Dependencies point inward, toward policy. State what the innermost layer is forbidden to know.
- **The composition root** — the one place that wires everything.
- **What must not leak inward.** Name the concrete types: the ORM context, the HTTP request, the
  provider's DTOs, the framework's attributes.
- **A diagram.** Modules as boxes, arrows for allowed dependency direction only.

Then the check: *could the HTTP layer and the datastore be deleted and the use cases still compile?*
If not, say where the leak is and fix the design before continuing.

## Step 3 — Domain model

- **Entities and aggregates**: name, what it represents, its identity, and its aggregate root.
- **Invariants**, stated as rules, each with where it is enforced. An invariant with no enforcement
  point is a comment.
- **Value objects** and why each exists rather than a primitive.
- **Lifecycles**: for anything with states, the state machine — states, allowed transitions, who
  triggers each, and which transitions are forbidden. Draw it.
- **Which operations are single calls on purpose** because they represent one fact and must not be
  separable.

## Step 4 — Data model

Concrete, per store. Not descriptions of fields — the fields.

- **Per table/collection**: name, purpose, and every column with **exact type, precision/length,
  nullability, default, and unit** where it has one.
- **Keys**: primary, foreign, and every unique constraint. For each unique constraint, what
  duplicate it prevents.
- **Every index, with the query it serves.** An index that cannot name its query does not belong.
- **Referential behaviour**: cascade, restrict, or set-null, per relationship, with the reason.
- **Nullability semantics**: for each nullable column, what null *means* — not yet known, not
  applicable, or genuinely absent. These are different and get confused.
- **What is stored versus computed**, and for anything derived-but-stored, how it is kept from
  drifting from its inputs.
- **What is stored for irreversibility**: raw payloads, rates applied, original figures — anything
  that cannot be recomputed once a conversion, rounding or aggregation has happened.
- **Migration strategy**: how schema changes are applied, whether existing rows are backfilled, and
  what a null means in rows written before a column existed.
- **Retention and volume**: expected row counts and growth, and what is ever deleted.

## Step 5 — Contracts

Every externally visible surface, fully specified.

- **Per endpoint**: method, path, auth requirement, request shape with types and validation rules,
  response shape with types, every status code it can return, and the error body shape.
- **Per message or event**: name, transport, queue/topic, payload with types, publisher, consumers,
  delivery guarantee, and idempotency key.
- **Per outbound call**: the service, the operation, request and response shapes, timeout, retry
  policy, and what your system does when it fails or never answers.
- **Versioning**: how a breaking change is introduced.
- **The error taxonomy**: the categories of failure, which status or code each maps to, and what the
  caller is expected to do about it. One shape, defined once.

## Step 6 — Component inventory

This is the "what classes do I create" answer. A table, one row per component, covering everything to
be built.

```markdown
| Component | Kind | Module/layer | Responsibility (one sentence) | Satisfies | Collaborators | Notes |
|---|---|---|---|---|---|---|
```

Rules for this table:

- **One sentence per responsibility, and it must not contain "and".** If it does, the component has
  two jobs — split the row.
- **Every component names the reason it exists.** A component whose row reads as forwarding is a
  layer with no purpose; remove it.
- **Interfaces and their implementations are separate rows**, with the module each lives in — the port
  belongs to the layer that needs it, the adapter to the layer outside.
- **`Satisfies` carries the requirement ids** this component exists for. An empty cell is a question to
  answer, not a cell to leave blank.
- **The inventory is exhaustive.** If a plan step later needs a class that is not in this table, this
  document was incomplete.

## Step 7 — Flows

For every significant use case, a numbered walkthrough. This is where correctness is actually decided.

**Each flow names the FR ids it implements, and that requirement's acceptance criteria are the flow's
success test** — do not restate them here in different words, or the two will drift and nobody will
know which is authoritative.

Per step: what is called, what it returns, what is written, what is published, and **what happens if
this step fails**. Then, for the flow as a whole:

- **Transaction boundaries** — what commits together, and what is deliberately outside the
  transaction.
- **Ordering that matters**, and why. Note anything that must be persisted before a remote call, or
  published only after a commit.
- **Idempotency** — what makes a repeat of this flow safe.
- **The failure matrix**: for each step, the failure, the resulting state, whether it is retryable,
  and whether it needs compensating.
- **What a reader of the stored record can tell afterwards** about how far the flow got. If the answer
  is "nothing", add it.

A flow with only a happy path is not specified. The failure behaviour will otherwise be invented
during implementation, under time pressure, by whoever hits it first.

## Step 8 — Rules and algorithms

Any non-obvious computation, ordering, matching or selection logic, written out precisely.

- **The formula or procedure**, unambiguously.
- **A worked example with real numbers**, and the expected output. This is the single most useful
  thing in the document and it is what an implementer will check their work against.
- **The edge cases**: empty, zero, negative, one element, ties, absent input, maximum, overflow,
  rounding direction.
- **Rounding, precision and units** wherever money, time or measurement is involved. State the
  rounding direction and where it is applied — this is a decision, not a detail.
- **Ordering rules**, where output order is part of the contract, and what the tie-break is.
- **Time and timezone**: what is stored, in what zone, and where conversion happens.

If a rule is easy to get wrong in a way that still looks plausible, say so explicitly and give the
wrong-but-plausible version alongside the right one.

## Step 9 — Cross-cutting concerns

Each of these, decided once and written down: authentication and authorization model; configuration
and secrets; logging and what must never be logged; metrics and health; error handling convention;
localization and text; caching and invalidation; background work and scheduling; file and blob
handling. Where one does not apply, say "not applicable" rather than omitting it — silence reads as
oversight.

## Step 10 — Performance, and how every NFR is met

Sized from the requirements' own numbers, not from imagination. **Do not restate an NFR's target
here** — cite the id and say what makes it hold.

One row per NFR, all of them, including the ones satisfied by doing nothing special:

```markdown
| NFR | Target (from 02) | Mechanism here | Verification | Residual risk |
|---|---|---|---|---|
| NFR-03 | p95 ≤ 300 ms @ 50 rps | covering index IX_…, no N+1, bounded page | probe, §11 | cold cache untested |
```

- **A mechanism of "n/a" or "the framework handles it" is a gap**, not an entry. Say which framework
  behaviour, and what happens when it does not apply.
- **`Verification` must match what phase 2 chose** — probe, structural check, dedicated plan, or not
  verified. If a target turns out to need a dedicated plan, that is a phase-2 amendment, not a
  quiet downgrade here.
- **Where a probe is the verification, specify it**: what it measures, what it runs against, and the
  number that counts as a pass. The probe is throwaway; this specification is what makes its result
  reproducible.

Then the performance work itself:

- **Expected load** and the resulting hot paths.
- **The specific optimizations chosen**, each with the reason and the cost it accepts.
- **What was deliberately not optimized**, and the threshold at which that should be revisited.
- **The known pathological cases** — the query that would table-scan, the N+1, the unbounded result
  set — and what prevents them.

Premature optimization and unexamined slowness are both failures. Name which risk you took.

## Step 11 — Test strategy

A decision, recorded, not a default. State what is tested, at what level, and with what command.

**One class is not optional: pure logic carrying a rule that was hard to get right.** Money and
rounding arithmetic, tax and commission splits, ordering and tie-breaks, parsing and code mapping,
state-transition guards, anything whose worked example in Step 8 took effort to get correct, and
anything a design record describes as having been wrong before. These have no I/O, so a test is
cheap, and they are exactly the code where a regression is both most likely and least visible. If
this project has such logic and no test covering it, that is a gap to name, not a preference.

Everything else is a judgement call — make it explicitly and write it down:

```markdown
| Level | What is covered here | What is deliberately not | Command |
|---|---|---|---|
| Unit | | | |
| Integration | | | |
| Contract | | | |
| Manual / probe | | | |
```

The levels, and what each is actually for:

- **Unit** — pure logic in isolation. Fast, deterministic, no database, no network, no clock. This is
  where the mandated class lives and where the Step 8 worked examples become test data directly.
- **Integration** — the real path through real dependencies: the database, the message bus, the
  provider. Expensive and slow, so choose a small number that cover the paths where money moves or
  data is written, rather than aiming at coverage.
- **Contract** — that an external service still returns the shape you mapped. Worth its cost the
  moment a provider's contract can move independently of your release, because that drift is silent:
  a field added upstream compiles fine and arrives unconverted.
- **Characterization** — locks in current behaviour before a refactor, so the diff proves equivalence.
  Where a project verifies refactors by probe-and-diff today, this is the same act made permanent.
- **Property-based** — for invariants rather than examples: a round-trip that must return the input, a
  stored value minus its recorded difference equalling the unrounded one, a sum that must equal its
  parts. One property replaces a table of cases and finds the input you would not have thought of.
- **Smoke** — the deployed thing answers and its dependencies resolve.

Then, honestly:

- **Which requirement ids are covered by a test**, and which rely on a probe, a structural check or
  nothing. This is the `Verification` column of the matrix; the test strategy has to agree with it.
- **What the verification command is**, exactly, so an implementer and a reviewer run the same thing.
- **If the project will have no automated tests, say so and say what replaces them.** In practice that
  means probes: name which requirements are verified that way, functional ones included, and where
  their recorded results live. "No tests" with nothing named in its place means nothing is verified —
  and it means every rule in this document is protected by prose alone, which does not fail a build.
- **What is deliberately not tested**, and why. Configuration wiring, framework behaviour, third-party
  libraries and trivial accessors are usually right to leave alone; saying so stops the question
  recurring at review.

## Step 12 — Security, decisions, open questions

- **Security and privacy**: what data is sensitive, what must never be returned to a client or written
  to a log, what is encrypted, credential lifetime and storage.
- **Decision record**: each significant technical decision, the alternatives, and why they were
  rejected. Rejected alternatives are what stop the same debate recurring.
- **Open questions**: each marked RESOLVE BEFORE IMPLEMENTATION or ESCALATE — DO NOT GUESS.

## Quality bars

Before declaring this done:

| Check | Requirement |
|---|---|
| Types | Every field has a concrete type, precision and nullability |
| Indexes | Each names the query it serves |
| Flows | Each has a failure path per step |
| Rules | Each has a worked example with real numbers |
| Components | Every responsibility is one sentence with no "and" |
| Versions | Every dependency pinned |
| Nulls | Every nullable field states what null means |
| Vagueness | No `TBD`, no `etc.`, no "as appropriate" |
| Vocabulary | Terms match the product spec glossary exactly |
| Coverage | Every `Must` requirement is served by at least one component or flow |
| NFRs | Every one has a mechanism row and a verification approach |
| Tests | Every hard-won rule in Step 8 is covered by a test, or the gap is named |
| Citations | No component with an empty `Satisfies`, no flow without an FR id |
| Matrix | The `Tech spec §` and `Components` columns in `02` are filled in |

Then the handoff test: **list what a competent stranger would still have to ask you.** That list is
your remaining work. Empty it or record each item as an open question.

## Then stop

Present the stack decision, the architecture, the assumptions and the open questions. Get approval
before writing the plan. The plan makes no new decisions, so an unapproved tech spec produces a plan
that has to be rewritten.
