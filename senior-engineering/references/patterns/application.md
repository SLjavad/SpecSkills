# Application patterns

Read when a design decides how use cases receive input, reach storage and report outcomes — or a review
finds one of these patterns. They sit between the entry points and the domain, in any architecture
style. `references/design.md` governs: the rich domain model, one error convention, concurrency and
idempotency, and "Balance" — each pattern names a present need, never "flexibility".

## Contents
- Commands and queries
- CQRS
- Repository
- The read side
- Specification
- Unit of work
- Result type
- Choosing the persistence shape
- Patterns left out

## Commands and queries

- **A command is one business task, named in the domain's language** — `BookRoom`, `CancelBooking` —
  not a data change: never `SetReservationStatus`, never `UpdateBooking` with every field optional.
  Its intent is what the handler, the log and the audit trail record.
- **A command changes state and returns little**: the new identifier, or the outcome of a business
  rule. **A query returns data and changes nothing** — no "get and mark as read", no lazily created
  record. A caller can repeat a query, cache it and retry it without thinking; break that and every
  one of those becomes a bug.
- **Both are plain data**, immutable where the language allows, carrying no behaviour and no framework
  type. They are the use case's input contract; the driving adapter maps its request into one.
- **One handler per command or query.** A class that handles twelve commands is a service with the
  same problems under a new name.
- **Validate the command's shape before the handler runs**, reporting every problem at once; the
  domain still enforces its invariants (`design.md`).

## CQRS

Command–query separation at the level of models. It comes in degrees, and each costs more than the
last — choose the lowest that solves a problem the project actually has, per module, and record it in
the ADR:

| Degree | What is separate | Earns its place when | Costs |
|---|---|---|---|
| **Separate handlers** | commands and queries are different types with different handlers | almost always — this is the default shape of a use case | nothing beyond the handlers |
| **Separate models, one store** | writes go through aggregates; reads project from the same database into read models | the read shapes differ from the aggregates, or loading aggregates for a list is slow | a second set of types, kept in step with the schema |
| **Separate stores** | a read store, often denormalized, fed by events from the write side | read and write loads differ by orders of magnitude, or the read side needs a different technology | eventual consistency, synchronization, an outbox, idempotent projections, rebuilds |

- **Most systems need only the first two.** Fowler and Microsoft agree that CQRS adds risky complexity
  and suits only parts of a system — a bounded context, not the whole — and that CRUD-shaped domains
  do not need it. A reporting database can relieve a heavy query without separating the models.
- **Separate stores are eventually consistent.** Say what a user sees right after their own write —
  read-your-own-writes from the write side, a version the client waits for, or a stated delay — and
  how a command acting on stale data is detected (an optimistic concurrency token, `design.md`).
- **The read store is fed by events published through an outbox** with idempotent projections
  (`references/architecture/event-driven.md`), and it can be rebuilt from the source of truth; a read
  store nobody can rebuild is a second source of truth.
- **CQRS does not require event sourcing**, messaging or a dispatcher library. Each is its own decision.

## Repository

A repository lets the use case treat the stored aggregates of one type as a collection: add one, find
one by identity, remove one (Fowler, *Patterns of Enterprise Application Architecture*; Evans,
*Domain-Driven Design*). Use one where the architecture keeps persistence out of the core, or where an
aggregate's loading rules deserve one home (`design.md`).

- **One repository per aggregate root, never per table.** It loads and saves the whole aggregate; the
  children of an aggregate have no repository of their own.
- **Its methods are named for the domain's needs** — `findByReference(reference)`,
  `findOverlapping(room, period)` — and return aggregates, or plain results for a check such as
  `existsWithEmail(email)`.
- **No generic repository** — `Repository<T>` with `getAll`, `find(predicate)`, `update(entity)` for
  every type. It is the ORM restated, with less power; it gives every non-aggregate a repository, and
  it lets each caller write its own query, so the query knowledge spreads instead of gathering here.
- **Never return a composable query object** from a repository — the ORM's deferred query type, or
  any object a caller can keep adding conditions to. The ORM leaks through the port, queries are
  built in every handler, and evaluation happens at a time the repository does not control.
- **The repository does not commit.** Saving registers the change; the use case commits once (Unit of
  work, below).
- **Fakes are simple** because the interface is small: an in-memory collection behind the same
  interface. The real repository is tested against the real database in a container
  (`references/testing.md`); a fake never proves a query.
- **Misuse**: a repository method per screen (`getBookingsForDashboardPage`) — that is a read, and
  belongs on the read side; business rules inside the repository; a service whose methods only
  forward to a repository.
- **Simpler**: where the ADR lets the use case use the ORM directly (see "Choosing the persistence
  shape"), the ORM's own context is already a repository and a unit of work, and another one over it
  needs its own reason.

## The read side

- **Reads bypass the aggregates.** A query projects straight from the store into its result type,
  selecting only the fields it returns; loading aggregates to build a list pays for invariants nobody
  changes, and for columns nobody reads.
- **A query handler, or a read port named for what it answers** — `BookingSummaries`,
  `AvailabilitySearch` — owns the query. Hand-written SQL is fine here; it is the read model's own
  language, and the integration test proves it.
- **Read models are plain data, shaped for the consumer**, with no domain logic (`design.md` "What
  stays plain on purpose"). One per screen or endpoint is normal; they change for the consumer's
  reasons, not the domain's.
- **Paging, filtering and sorting are part of the query's contract**: bounded page sizes, sorting only
  on indexed or declared fields, and a stable order so a page is never repeated or skipped.
- **Authorization applies to reads too** — the query filters to what the caller may see, in the query,
  never by loading everything and filtering afterwards.
- **Misuse**: a read model reused as a command's input; a query that writes; an aggregate exposed as a
  query result because "it already has the fields".

## Specification

A named, reusable business predicate: `OverdueInvoice`, `EligibleForDiscount` (Evans and Fowler).

- **Problem**: the same rule — what makes an invoice overdue — is needed in more than one place: to
  check one object in memory, to select matching records from the store, or both. Written twice, the
  two copies drift.
- **Earns its place** when one rule is used in two of those places, or when rules are combined
  (`overdue and not disputed`) in ways that vary by use case.
- **Shape**: a class or function named for the rule, holding the domain knowledge itself — the
  threshold, the states. It answers "does this object satisfy me" and, where it is also used for
  querying, translates itself to the store's criteria in the persistence adapter. Combinators (and,
  or, not) only once rules are actually combined.
- **Misuse**:
  - a generic specification that carries whatever condition the caller passes in — it holds no domain
    knowledge, and is a query object with extra steps (Khorikov);
  - a specification used as a validator for an invariant — invariants live in the entity, which is
    never invalid (`design.md`);
  - a specification for a rule used once.
- **Simpler**: a well-named method on the entity (`invoice.isOverdue(today)`) plus one well-named
  repository method that applies the same rule in the query, side by side with a test that proves
  they agree.

## Unit of work

The unit of work tracks what a business transaction changed — new, modified and removed objects — and
writes it out in one go at the end, handling concurrency conflicts (Fowler, *PoEAA*).

- **One use case, one unit of work, one commit.** The handler, or the pipeline around it, commits once
  at the end; a repository, a domain service or an event handler never commits behind its back.
- **Most ORMs already are one.** Do not wrap the ORM's context in a second unit-of-work abstraction
  with the same methods; the port exposes one way to commit, or the ADR lets the use case use the
  ORM's own.
- **Two aggregates in one commit** are fine in one database when the use case needs them consistent
  together; across databases or services it is not a unit of work but a distributed transaction —
  use an outbox and eventual consistency instead, and a saga when the steps must all complete or be
  compensated (`references/architecture/event-driven.md`).
- **The commit is where concurrency is decided**: an optimistic concurrency conflict surfaces here,
  and the use case states what the caller gets — a retry, a conflict response, a merge (`design.md`
  "Concurrency and idempotency").
- **Domain events raised during the work** are dispatched at a point the project states — before the
  commit inside the transaction, or after it through an outbox (`references/patterns/code.md`
  "Observer and in-process events").
- **No transaction held open across user interaction or a remote call.** Load, decide, commit;
  call the slow outside system before or after, never while holding locks.

## Result type

An expected business outcome — slot taken, insufficient funds, booking already cancelled — is returned
as a typed result the caller must handle; a broken invariant or a bug fails fast (`design.md`, one
error convention). This section says where the result type stops paying for itself.

- **Shape**: success with a value, or a failure with a stable code the caller can branch on and a
  message for people. The failure cases of one use case are a closed, named set, so the driving adapter
  maps each to a delivery format exactly once.
- **Use it for outcomes the caller must decide about.** Not for:
  - failures nobody can handle where they occur — I/O errors, a lost connection, a missing
    configuration — which stay the language's failure mechanism and are handled once at the top;
  - bugs, which need the stack trace a result type throws away;
  - code where callers only care whether it worked.
  (Wlaschin, "Against Railway-Oriented Programming".)
- **Do not rebuild exception handling out of results.** Some exceptions will escape anyway, and the
  top-level handler still exists; a result that wraps every exception is try/catch with worse tools.
- **Never ignore a result.** A failure the caller drops is a silent wrong answer. Use the language's
  or the analyzer's support for must-use return values where it has one.
- **Where the language's idiom is exceptions for business outcomes**, follow the project's recorded
  convention instead — one convention per codebase beats a mixture of two.

## Choosing the persistence shape

The project picks one write-side shape per module, records it in the architecture ADR, and the
architecture tests enforce it:

- **A port in front of persistence** — a repository per aggregate and one way to commit; the default
  where the core must not know the persistence technology (`references/architecture/clean.md`).
- **The use case uses its data access directly** — fewer types, and the data access's semantics in
  the use cases; fits vertical slices and small modules, and a Clean module only where the ADR allows
  that one outward reference (`references/architecture/vertical-slice.md`).

Either shape is implemented with an ORM, a thin data mapper or plain SQL — a technology choice for the
stack playbook, not a third shape. Plain SQL fits where the ORM cannot map the aggregate, a legacy
schema fights it, or a hot write needs an exact statement; the mapping is then hand-written and tested
against the real database. The read side may differ from the write side: a module can save through
repositories and read through SQL projections.

## Patterns left out

- **Active record** — the entity saves itself, so persistence enters the domain; acceptable only for a
  module recorded as plain CRUD (`design.md`).
- **Transaction script** — one procedure per use case with no domain model; the starting point of a
  slice, which moves to the rich model once rules appear (`references/architecture/vertical-slice.md`).
- **Service layer** — the application ring's handlers already are one; a separate service per entity
  that only forwards is the anemic model.
- **Event sourcing** — storing the events as the source of truth; a decision with its own costs
  (`references/architecture/event-driven.md`), never a side effect of choosing CQRS.
- **Saga and process manager** — coordination across aggregates or services
  (`references/architecture/event-driven.md`).
- **Identity map, lazy load, data mapper internals** — the ORM's business, not the application's.
