# Phase 3, part 1 — Technical spec: structure

**Goal:** the roadmap. Detailed enough that an implementer creates the right classes, tables, types and
flows without asking you anything, and specific enough that two implementers working from it
independently would produce substantially the same system. Vagueness here becomes improvisation later.

This part fixes **what exists**: stack, architecture, domain, data, contracts, components. Part 2,
`tech-spec-behaviour.md`, fixes how it behaves and how you will know it works.

**Hard rule: no product decisions and no new requirements.** If writing this surfaces a question about
what the product should do, go back to phase 1. If it surfaces a requirement nobody wrote down, add it
in phase 2. Neither gets settled here, and neither gets buried in a design paragraph.

**Hard rule: the tech spec satisfies the requirements, so it cites them.** Every component, flow and
performance decision names the `FR-`/`NFR-` ids it serves, and you fill in the `Tech spec` and
`Components` columns of the traceability matrix as you go. A design element serving no requirement is
either scope creep or a missing requirement — resolve which; do not leave it.

Write to `docs/specs/03-tech/` — or, for a later change, as tech deltas (`changes.md`). Significant
decisions go to `docs/adr/`.

## Contents
- The files
- Step 1 — Choose the stack, with the user
- Step 2 — Architecture
- Step 3 — Domain model
- Step 4 — Data model
- Step 5 — Contracts
- Step 6 — Component inventory

## The files

| File | Holds |
|---|---|
| `stack.md` | One line per concern: choice, pinned version, the ADR that decided it |
| `architecture.md` | Style, modules and dependency direction, composition root, forbidden leaks, diagram |
| `domain/<aggregate>.md` | One aggregate per file |
| `data/<store-or-context>.md` | Tables or collections for one store or bounded context |
| `contracts/<surface>.md` | One API area, message group or outbound integration per file; `contracts/errors.md` holds the error taxonomy |
| `components.md` | The component inventory; split per module past 300 lines |
| `flows/`, `rules/`, `cross-cutting.md`, `performance.md`, `testing.md`, `security.md` | Part 2 |

The rationale of every significant decision lives in its ADR. These files state the choice in one line
and link the ADR — never a copy of the reasoning, which would drift.

## Step 1 — Choose the stack, with the user

The stack is **not** assumed and **not** inherited from whatever you saw last. It is the first decision
of this phase, and it is the user's to make. Discuss it, then record it.

**Start from the architecturally significant NFRs**, which phase 2 flagged for exactly this. Every stack
ADR cites them by id: if nothing in the requirements drove the choice, it was made on preference, and
saying so honestly is better than dressing it up.

Bring the user a recommendation with reasons and real alternatives — researched, not remembered
(`discovery.md`, "Research"). What to weigh:

- **What the team already runs.** An unfamiliar-but-better stack is usually worse. Ask what they operate
  today, and what they are willing to operate.
- **Fit to the problem.** Heavy concurrency, heavy data, heavy UI, scheduled batch, real-time — these
  point different ways.
- **The scale numbers from the product spec.** Do not choose for a scale nobody stated.
- **Obligatory integrations.** An SDK that exists for one ecosystem and not another decides more than
  taste does.
- **Deployment and operational reality.** Where does this run, who watches it, what does the team
  already have for logs, metrics, CI, secrets.
- **Persistence shape.** Relational, document, key-value, search, time-series, or several — driven by the
  access patterns, not by preference.
- **Team size and lifespan.** A one-person tool and a system a team maintains for five years justify
  different structure.
- **Support horizon and licences.** How long each pinned version is supported, and whether any component
  carries licence terms the user must accept.

Record each significant choice as an ADR (senior-engineering `decision-records.md`) with status
`proposed`; the user accepts it. Then summarize in `stack.md`:

```markdown
| Concern | Choice | Version | ADR |
|---|---|---|---|
| Language / runtime | | | |
| Framework | | | |
| Persistence and migrations | | | |
| Messaging / jobs | | | |
| Testing (unit, integration, mutation, architecture) | | | |
| Build / CI | | | |
| Hosting / runtime target | | | |
| Observability | | | |
```

**Pin versions.** "Latest" is not reproducible and will not be the same next month.

**Then write the stack playbook** — `docs/engineering/stack-<name>.md` for each stack, following
senior-engineering's `modern-practices.md`: the current idioms, performance practice, superseded
patterns and test toolchain for exactly these versions, researched and dated. The rest of the tech spec
is written concretely in that ecosystem — its real type names, project layout and idioms. Generic
pseudo-guidance is what this phase exists to avoid.

## Step 2 — Architecture

- **Style, named and justified**: layered, clean, hexagonal, modular monolith, services, vertical
  slices. State why it fits *this* project's size and team, not why it is good in general — as an ADR.
- **Module boundaries and the dependency direction.** List every module and what it may depend on.
  Dependencies point inward, toward policy. State what the innermost layer is forbidden to know.
- **The composition root** — the one place that wires everything.
- **What must not leak inward.** Name the concrete types: the ORM context, the HTTP request, the
  provider's DTOs, the framework's attributes.
- **A diagram**, as Mermaid `graph`: modules as boxes, arrows for the allowed dependency direction only.
- **Architecture tests** that enforce the above — named here as the *Confirmation* of the architecture
  ADR, and built by an early plan step.

Then the check: *could the HTTP layer and the datastore be deleted and the use cases still compile?* If
not, say where the leak is and fix the design before continuing.

## Step 3 — Domain model

Domain entities are **rich** — senior-engineering's `design.md` has the rules. One file per aggregate:

- **The aggregate root and its entities**: what each represents, its identity.
- **Behaviour**: the intention-revealing operations the aggregate exposes, each with the invariants it
  enforces, the events it raises, and the typed outcomes it can return.
- **Invariants**, stated as rules, each with where it is enforced. An invariant with no enforcement
  point is a comment.
- **Value objects**, and why each exists rather than a primitive.
- **Lifecycle**: for anything with states, the state machine as Mermaid `stateDiagram-v2` — states,
  allowed transitions, who triggers each, and which transitions are forbidden.
- **Operations that are single calls on purpose**, because they represent one fact and must not be
  separable.
- **What is exposed read-only**, and what reads bypass the aggregate through projections.
- **Classification**: rich (the default), or plain CRUD with the reason it has no invariants to protect.
  The user approves every plain-CRUD classification at the gate.

## Step 4 — Data model

Concrete, per store. Not descriptions of fields — the fields.

- **Per table or collection**: name, purpose, and every column with **exact type, precision or length,
  nullability, default, and unit** where it has one.
- **Keys**: primary, foreign, and every unique constraint. For each unique constraint, what duplicate it
  prevents — including the ones that arbitrate idempotency.
- **Concurrency**: the version or concurrency token on every row two writers can contend for.
- **Every index, with the query it serves.** An index that cannot name its query does not belong.
- **Referential behaviour**: cascade, restrict, or set-null, per relationship, with the reason.
- **Nullability semantics**: for each nullable column, what null *means* — not yet known, not
  applicable, or genuinely absent. These are different and get confused.
- **What is stored versus computed**, and for anything derived-but-stored, how it is kept from drifting
  from its inputs.
- **What is stored for irreversibility**: raw payloads, rates applied, original figures — anything that
  cannot be recomputed once a conversion, rounding or aggregation has happened.
- **Sensitive columns**: which hold personal, financial or secret data, and how each is protected.
- **Migration strategy**: how schema changes are applied, whether existing rows are backfilled, and what
  a null means in rows written before a column existed.
- **Retention and volume**: expected row counts and growth, and what is ever deleted.

## Step 5 — Contracts

Every externally visible surface, fully specified.

- **Per endpoint**: method, path, authentication and the authorization rule (who may call it, on which
  objects), request shape with types and validation rules, response shape with types, every status
  code it can return, the error body, and what a repeated call returns.
- **Per message or event**: name, transport, queue or topic, payload with types, publisher, consumers,
  delivery guarantee, and idempotency key.
- **Per outbound call**: the service, the operation, request and response shapes, timeout, retry policy,
  and what your system does when it fails or never answers.
- **Versioning**: how a breaking change is introduced.
- **The error taxonomy**, in `contracts/errors.md`: the categories of failure, the status or code each
  maps to, and what the caller is expected to do about it. One shape, defined once.

## Step 6 — Component inventory

This is the "what classes do I create" answer. A table, one row per component, covering everything to be
built.

```markdown
| Component | Kind | Module/layer | Responsibility (one sentence) | Satisfies | Collaborators | Notes |
|---|---|---|---|---|---|---|
```

- **One sentence per responsibility, and it must not contain "and".** If it does, the component has two
  jobs — split the row.
- **Every component names the reason it exists.** A component whose row reads as forwarding is a layer
  with no purpose; remove it.
- **Interfaces and their implementations are separate rows**, with the module each lives in — the port
  belongs to the layer that needs it, the adapter to the layer outside.
- **`Satisfies` carries the requirement ids** this component exists for. An empty cell is a question to
  answer, not a cell to leave blank.
- **The inventory is exhaustive.** If a plan step later needs a class that is not in this table, this
  document was incomplete.

Continue with `tech-spec-behaviour.md`.
