# Modular Monolith

Read when the project's architecture ADR chose a modular monolith, when a monolith is being split into
modules, or when a module is about to become a service. It adds the rules between modules; inside a
module, its own style applies (`references/architecture/clean.md` or
`references/architecture/vertical-slice.md`), and `references/principles/design.md` applies throughout.

A modular monolith is one deployable unit made of modules with hard boundaries: each module owns its
behaviour and its data, and the others reach it only through its public contract. The boundaries are
the same as a service's; only the deployment is shared.

## Contents
- When it fits
- What a module is
- The public contract
- Data ownership
- Queries between modules
- Commands between modules
- Failure without a shared transaction
- Shared code
- Reporting and screens across modules
- Enforcement
- Signs of drift
- Splitting a module out

## When it fits

- **The default for a system with several business areas.** It gives the boundaries of services
  without the cost of distribution — network failures, distributed tracing, independent deployment
  pipelines, data spread across stores.
- **Monolith first** (Fowler): boundaries are hard to get right up front, and moving them inside one
  codebase is far cheaper than across services. Splitting a module out later works only where the
  module boundaries were kept.
- **Microservices instead**, only for a present, stated need — independent deployment by separate
  teams, very different scaling or availability, a separate technology
  (`references/architecture/microservices.md`). A team that cannot keep a monolith modular will
  build a distributed big ball of mud instead (Brown).
- **A single small area** with one team and one model does not need modules; one well-organised
  application is enough.

## What a module is

- **A business capability, ideally one bounded context** — Orders, Payments, Catalogue — with its
  own language and model (`references/architecture/ddd-strategic.md`). Not a technical layer, and not
  one entity: a module per table is a distributed data model in one process.
- **High cohesion inside, low coupling between.** If two modules change together for most features, or
  one cannot do anything without the other's data, the boundary is in the wrong place.
- **Each module chooses its internal style** — Clean for a core with complex rules, slices for a
  supporting module — recorded per module in the architecture ADR.
- **Each module has its own composition root or registration**, called by the host; a module's wiring
  never reaches into another's internals.

## The public contract

- **A module exposes a small contract and nothing else**: the commands it accepts, the queries it
  answers, the integration events it publishes, and the plain data types they carry.
- **Everything else is internal**, by the language's own visibility mechanism wherever it has one —
  internal types, unexported names, separate packages that only expose the contract.
- **The contract is not the domain model.** Contract types are plain data designed for other modules;
  a contract that returns the module's entities lets every caller depend on its internals.
- **Other modules reference only the contract** — never the domain, the handlers or the persistence of
  another module.
- **The contract is versioned like a public API** once more than one team uses it: additive changes
  are free, breaking changes go through a deprecation period.

## Data ownership

- **Each module owns its data** — its own schema, or its own tables with a clear owner — and is the
  only code that reads or writes it.
- **No joins across modules, no shared tables, no foreign keys between modules' tables.** A module
  stores another module's identifier as a plain value, and asks for the rest through the contract or
  keeps its own copy updated by events.
- **One database server is fine; shared ownership is not.** Separate schemas and, where the database
  allows, separate credentials make an accidental cross-module query fail instead of working quietly.
- **Each module migrates its own schema**, and a module's migration never touches another's.

## Queries between modules

- **A module may query another synchronously, through its contract** —
  `Catalogue.getProductSummary(id)` — because a query changes nothing: if it fails, the caller retries
  or fails the request, and nothing is left half done.
- **Mind the coupling it still creates**: the caller now depends on the other module being up and
  fast. For data read constantly, keep a local copy updated by the owner's events instead.
- **Never a query that changes state** — a "get" that also records or reserves is a command and
  follows the rules below.

## Commands between modules

Each module commits its own transaction, so a command to another module never commits together with
the caller's change. It crosses in one of two ways:

| The caller | How |
|---|---|
| needs the result to answer now — the charge must succeed before the order is confirmed | a **synchronous command** through the other module's contract, under the rules below |
| only needs the other module to react, now or later | an **integration event**, published through an outbox in the same transaction as the change (`references/architecture/event-driven.md`) |

A synchronous command:

- **carries an idempotency key** — a unique identifier the caller creates once per intended change.
  The receiver stores the key with its change in one transaction and answers a repeat with the first
  result, so resending is always safe.
- **is never sent while the caller's transaction is open.** The caller first commits its own change
  in a pending state that holds the key — `PendingPayment` — then sends the command, then records the
  outcome in a second transaction.
- **has three outcomes, each handled**: done — the caller confirms; refused for a business reason —
  the caller moves to its failure state and compensates any step already done; unknown — a timeout or
  a crash — the caller stays pending.
- **is settled by a reconciliation job when it stays pending**: the job resends the command with the
  same key, which returns the original result if it already ran, and escalates what is still pending
  at its deadline.

- **A process of several steps** repeats these rules per step, compensating the finished steps in
  reverse order when a later one is refused; where such processes grow long, use a saga
  (`event-driven.md`).
- **The entry point** — an endpoint, a job, a UI — calling one module's contract is not one module
  calling another; it follows the same rules only when it also changes its own state.
- **No transaction spans two modules**, even in one database. It couples their data and stops working
  the day one module is split out. If two modules truly must change atomically every time, they are
  one module.

## Failure without a shared transaction

When the change travels as an integration event, each step commits locally and failures are handled
by kind:

| Failure | Handling |
|---|---|
| the first module's commit fails | nothing happened and no event exists — the event is in the same transaction |
| a crash after the commit, before the event leaves | the outbox relay sends it later |
| the receiving module fails transiently | redelivery with backoff; the receiver is idempotent — an inbox or a dedupe key — so a second delivery has no effect |
| the receiving module refuses for a business reason | no retry; it publishes a failure event and the first module compensates |
| it keeps failing for an unknown reason | bounded redelivery, then a dead-letter queue and an alert |
| no answer arrives | the pending state has a deadline; a reconciliation job finds what is stuck and releases or escalates |

- **Model the in-between states** — `PendingPayment` — as real states with their own rules, visible to
  users where they matter.
- **Nothing waits forever**: every pending state has a deadline and something that checks it.

## Shared code

- **Technical plumbing is shared** — logging, the request pipeline, the result type, the outbox and
  the in-process bus.
- **A shared kernel is deliberately tiny**: value objects that genuinely mean the same in every module
  — `Money`, perhaps an identifier type — changed only with the agreement of every module that uses it.
- **Domain types are never shared across modules.** Each module models what it needs; a `Customer` in
  Billing and a `Customer` in Support are different models of the same person.
- **No `Common` or `Utils` package** — it becomes the channel through which modules couple.

## Reporting and screens across modules

- **A screen that shows several modules' data** is composed from each module's queries — in the
  driving adapter, or a backend-for-frontend — never by joining their tables.
- **A report across modules** reads a reporting read model that is fed by the modules' integration
  events, or owned by a reporting module that receives copies; it does not read the modules' tables
  directly.
- **Search and analytics** follow the same rule: fed by events or exports the owning module publishes.

## Enforcement

Folders are not walls. Boundaries hold only where the build fails when one is crossed:

- **Architecture tests**, failing the build (`design.md` "Enforce the structure"):
  - a module references another module's contract only — never its domain, application or
    persistence;
  - no cycles between modules;
  - no module accesses another module's schema or tables;
  - contract types do not expose domain types.
- **Separate compiled packages per module**, with only the contract public, let the compiler enforce
  most of this; one package with modules as folders needs the tests to do it all.
- **Database permissions per module**, where the database supports them, make data ownership a fact.

## Signs of drift

Treat each as a review finding:

- a join, a view or a foreign key across modules' tables;
- a module reading another's tables "just for a report";
- a contract that returns entities, or mirrors one module's internal model;
- a command to another module without an idempotency key, or sent while the caller's transaction is
  open;
- a transaction spanning two modules;
- cycles between modules, or one module that every other one depends on;
- a shared kernel that keeps growing, or a `Common` package;
- most features needing changes in the same two modules — a boundary in the wrong place.

## Splitting a module out

When a stated need makes one module a service (`references/architecture/microservices.md`):

- **its contract becomes the service's API**, and its integration events move from the in-process bus
  to a broker — the outbox and the idempotent consumers already handle the delivery;
- **its schema moves to its own database**, which is a move, not a redesign, because nobody else
  reads it;
- **synchronous queries and commands become network calls**, now with timeouts, retries and breakers
  (`references/patterns/resilience.md`) — review each one, and replace the hot queries with local
  copies fed by events.

A module that kept these rules splits in steps; a module that broke them has to be redesigned first.
