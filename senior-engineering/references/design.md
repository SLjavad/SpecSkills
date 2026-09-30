# Design

How to shape a change so it is correct, testable, and hard to get silently wrong. Read before
designing anything beyond a local change, and before reviewing a design.

These are the principles most often at stake, not the complete set. Apply the wider body of design and
architecture principles wherever they bear — separation of concerns, cohesion and coupling, DRY, KISS,
YAGNI, encapsulation, composition over inheritance, and the rest (`review.md` lists their signals) — and
weigh them against each other; "Balance" below settles the conflicts.

## Contents
- The dependency rule
- SOLID, as decisions rather than definitions
- Rich domain model
- Keeping logic out of the UI layer
- Design against silent wrongness
- Safe defaults and failure direction
- Concurrency and idempotency
- Irreversibility
- Balance
- Enforce the structure with architecture tests

## The dependency rule

Dependencies point **inward**, toward policy and away from mechanism. Domain and use cases know
nothing about the web framework, the ORM, the message bus, the UI framework, or the provider SDK.

- **The test:** could you delete the HTTP layer and the database and still compile the use cases? If
  not, the mechanism has leaked inward.
- **A framework or vendor type in a domain or use-case signature is a leak** — an ORM context or
  entity attribute, an HTTP request object, a provider's DTO. Map at the boundary instead.
- **Ports belong to the inner layer, implementations to the outer.** The interface lives with the
  code that *needs* it, named for what it needs; the adapter lives outside and depends inward.
- **Only the composition root knows everything.** If a second place has to know how the whole graph
  is wired, wiring has escaped.

## SOLID, as decisions rather than definitions

- **Single responsibility — one reason to change.** Name the change that would force you to edit this
  class. If you can name two unrelated ones ("the tax rules moved" and "the client contract moved"),
  split along that line. Split by *reason to change*, never by line count.
- **Open/closed — extend at the seam you already have.** If adding the fourth variant means editing
  the same three `switch` statements, the variance wants a type. If it is the *second* variant, a
  branch is still cheaper than a hierarchy. Do not build the seam before the second case.
- **Liskov — a subtype that throws on a base member is lying.** So is one that tightens a
  precondition. If an implementation cannot honour the contract, the contract is wrong or the
  hierarchy is.
- **Interface segregation — no consumer should depend on members it never calls.** A twelve-member
  interface where each caller uses two is four interfaces wearing one name. This matters most for
  test doubles and for reading: a narrow port tells you what the collaborator is *for*.
- **Dependency inversion — depend on abstractions you own.** Wrapping a stable library in your own
  interface for purity's sake is cost with no benefit; wrapping the thing that will change, or that
  you must fake to test, is the whole point. Decide by "will this change independently of me", not
  by category.

## Rich domain model

Domain entities are rich: they own their rules and their state changes. An entity that is a bag of
getters and setters, with its rules spread across services, handlers and controllers, is the anemic
model — it pays the full cost of a domain model and gets none of the benefit, and it is the shape an
agent produces by default. Treat it as a defect.

- **State changes only through intention-revealing methods** that validate before they mutate —
  `booking.Cancel(reason, now)`, not `booking.Status = Cancelled`. No public setters on domain state.
- **Valid from creation.** A constructor or factory establishes every invariant, so an invalid entity
  cannot exist. The constructor the ORM uses is private or protected and has no side effects — no
  events raised, no ids generated, no clock read.
- **Collections are encapsulated**: a private mutable field, a read-only view outward, and add/remove
  methods that enforce the rules.
- **Value objects by default** for concepts with rules — money, quantities, date ranges, identifiers,
  addresses: immutable, compared by value, validated when created. A bare primitive for such a
  concept is how an amount in the wrong currency gets stored.
- **Aggregates are consistency boundaries.** Model true invariants inside one aggregate, keep
  aggregates small, reference other aggregates by identity, and use eventual consistency between
  them. One transaction changes one aggregate unless a stated reason says otherwise. Only aggregate
  roots get repositories.
- **Domain events record what happened.** The aggregate raises them; the unit of work dispatches them.
  Anything that leaves the process goes through a transactional outbox, and its consumers are
  idempotent because delivery is at-least-once.
- **Application services orchestrate, they do not decide**: load, call domain behaviour, save,
  publish. A business rule in a handler, controller or component is in the wrong place. A rule that
  spans aggregates lives in a domain service or an event-driven process.
- **Time, identifiers and randomness are injected**, never read from ambient statics inside the
  domain, so behaviour is deterministic under test.
- **One error convention per codebase, in the language's idiom.** A broken invariant fails fast — the
  language's mechanism for bugs. An expected business outcome (slot taken, insufficient funds) is a
  typed result the caller must handle.
- **Strongly typed identifiers** where mixing two ids up is a real risk — not by reflex.
- **Map through the ORM's support for private state** — field access, embedded or complex value
  types, value converters. If the persistence technology cannot map private state, map in the
  repository. Never open a setter for the ORM's convenience.

**What stays plain on purpose:** DTOs, commands, API contracts, read models and projections (reads
bypass aggregates and project straight into DTOs), integration messages, configuration objects, and
client-side caches of server state. They carry data across a boundary; they are not domain entities.

**Plain CRUD is a decision, not a default.** A module with genuinely no rules — reference data, admin
lookups, reporting — may use plain records, but the classification is written in the tech spec with
its reason, where the user approves it. "It was simpler" is not the reason; "there is no invariant to
protect" is.

## Keeping logic out of the UI layer

The same rule holds on the client, whatever the UI framework. Components render and dispatch events;
business rules live in framework-free modules with their own unit tests; the framework's orchestration
layer (hooks in React, view-models elsewhere) coordinates; API clients live in a data layer. Derive
values during rendering instead of synchronizing them through side effects. Replace the
same condition scattered through components with one strategy. Client-side validation is for the
user's convenience — the server enforces the invariant, always.

## Design against silent wrongness

Loud failures get fixed. Silent ones become the bug found in a quarterly reconciliation. Prefer, in
this order:

1. **Make the mistake impossible.** Required/named constructor parameters instead of four adjacent
   same-typed positional ones. A value object instead of a bare decimal. A computed property instead
   of a stored duplicate. Types that cannot represent the invalid state.
2. **Make it loud.** Fail fast at startup on invalid configuration. Throw on the absent case that
   means a real fault, rather than returning null and letting a caller read it as "not yet".
3. **Only then, validate and document.**

Ask of every change: *if I got this exactly backwards, what would tell me?* If the answer is
"nothing — the totals still add up", stop and redesign until something would.

Two specific traps worth naming:

- **A derived value stored beside its inputs will drift.** If you must store it — because someone
  reads the table directly, or it must be queryable — write it from the single computed expression at
  save time so the two cannot disagree, and never let anything assign it by hand.
- **Two code paths that answer the same question must be one path.** If two methods agree today, a
  reader has to prove it, and a maintainer will break it. Collapse them.

## Safe defaults and failure direction

- **The safe value must be the one you get by saying nothing.** Absent config means the feature is
  off. An unset flag means the conservative behaviour. If omitting something enables the dangerous
  path, the default is wrong.
- **Choose which way to fail on purpose.** "Did not charge them" and "charged them twice" are not
  equally bad; neither are "refused a valid request" and "accepted an invalid one". Name the
  direction you chose and why.

## Concurrency and idempotency

Every write path is designed for the second copy of itself: the retry, the redelivered message, the
double click, two users acting at once.

- **Idempotency is a design decision, not a retry setting.** Anything that can be redelivered,
  retried, or double-submitted needs a key that makes the second attempt a no-op — and a stated
  answer for what the second caller receives.
- **Let the database arbitrate.** A unique constraint decides duplicates; an optimistic concurrency
  token detects a lost update. A read-then-write check in application code is a race.
- **Commit the dedupe marker and the side effect together**, in one transaction, or the marker lies.
- **Name the contended resources** — the last seat, the balance, the counter — and choose per resource:
  optimistic token, pessimistic lock, atomic conditional update, or a single-writer queue.
- **Never block on asynchronous work** from inside asynchronous code. Bound every pool and queue, and
  say what happens when it is full.

Concurrency and idempotency are two of the failure properties a design must decide; resilience to a
slow or failing dependency, data consistency across separate updates, and compatibility with old
clients and old data are others. Decide each one the system actually has, and `testing.md` asks the
tests to challenge them.

## Irreversibility

Some information cannot be recovered later, and that is what deserves to be stored.

- **A conversion, rounding, or aggregation cannot be undone.** If you keep only the result, the input
  is gone. Keep what an audit, a dispute, or a reconciliation would need — the raw figure, the rate
  applied, the payload actually sent.
- **A field left out now is not recoverable retroactively.** Storing the whole response is usually the
  same amount of work as storing the useful subset, and the subset is a guess about future questions.
- **Distinguish "absent" from "zero" and from "unknown".** Nullable where never-computed is a
  meaningful state. Do not backfill a number you would have to invent.

## Balance

Failure has two directions, and over-engineering is the more common and the harder to see, because
every individual piece looks defensible.

**Too much.** Do not:

- Add an abstraction, interface, or pattern for a single case. One handler needs no handler
  framework; one implementation needs no strategy.
- Build for a requirement nobody has stated. "We might need to swap the database" has cost today and
  benefit never.
- Split one decision across several methods, so no single place answers "what does this return and
  why".
- Leave a chain of one-line helpers between the entry point and the code that actually decides.
- Introduce a layer whose only job is forwarding.

**Too little.** Do not:

- Collapse distinct concerns because it is shorter.
- Write clever code. If a reader must re-read the line to see why it is correct, revert it —
  understanding at a glance is the goal.
- Remove an abstraction that names a concept, even with one caller today.
- Hide branching in dense one-liners or chained ternaries.
- Make debugging harder: keep the stack readable and intermediate values inspectable.

**The test for both directions.** Open the entry point as if you had never seen it and read downwards.
If you can state what it does and what it returns without descending past one level of helper, the
decomposition is right. Four hops to find the decision means over-fragmented — even when every method
is small, pure and well named. Five unrelated things to hold at once means under-decomposed.

Two callers is not duplication worth an abstraction. Three similar blocks usually are. A helper with
one caller earns its place only by naming a concept the call site cannot express.

## Enforce the structure with architecture tests

Rules that live only in prose erode. Encode the structural ones as architecture tests — fitness
functions that fail the build: the domain references no ORM, web or UI framework; module dependencies
point only inward; no cycles between modules; the rules an ADR's *Confirmation* section names. Start
from the current state — fail on *new* violations and baseline the legacy ones — so the test gets
adopted instead of muted. The project's stack playbook names the maintained tool.
