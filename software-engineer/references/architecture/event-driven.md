# Event-Driven Architecture

Read when a change crosses a module or service boundary as a message, or when a design uses events,
an outbox, a saga or event sourcing. A change whose caller needs the answer now crosses as a
synchronous command instead (`references/architecture/modular-monolith.md` "Commands between
modules"); in-process domain events are in `references/patterns/code.md` "Observer and in-process
events". The broker, the outbox and inbox implementation, and any messaging or workflow library are
stack decisions (`references/principles/modern-practices.md` "The stack playbook").

## Contents
- When it fits
- Events and commands
- Publishing: the outbox
- Consuming: the idempotent consumer
- Ordering
- Failures and the dead-letter queue
- Sagas
- Coordinating a saga
- Event sourcing
- Contracts and versioning
- Observability
- Testing
- Signs of drift

## When it fits

- **Several parts react to the same fact**, and the producer should not know them: a new consumer is
  added without changing the producer.
- **The reaction can happen later.** The business accepts that parts of the system disagree for a
  while, and users see what is true in the meantime — a pending state, a stated delay.
- **The producer must keep working** while a consumer is down or slow.
- **Not for** a caller that needs the answer to respond now — a synchronous call
  (`references/architecture/microservices.md` "Communication"); not for a change that must be
  consistent everywhere at once — that is one module; and not without the practice it demands:
  debugging, monitoring and recovery differ from request–response (Microsoft).

## Events and commands

| | Event | Command |
|---|---|---|
| Says | something happened — `OrderPlaced`, past tense | do something — `ReserveStock`, imperative |
| Receivers | any number, unknown to the sender | exactly one, known to the sender |
| The receiver | decides what the fact means for itself | may refuse, and the sender handles the refusal |

- **An event that expects one particular reaction is a command in disguise** (Fowler). If the sender
  needs the stock reserved, it sends `ReserveStock`; an event would hide a dependency it still has.
- **Domain events stay inside the module; integration events cross its boundary.** An integration
  event is mapped from a domain event once the change has committed, designed for its consumers, and
  versioned as a public contract. Domain events are never published as they are — every consumer
  would come to depend on the module's internal model (Microsoft, Dudycz).
- **An event is a business fact** in the domain's language: what it is about, when it happened, and
  the data its consumers need. Never a row change, a generic "entity updated", or a dump of the
  entity.
- **The payload is decided per event, by what its consumers need**:
  - an **identifier only**, when consumers need fresh data anyway or the data is sensitive — each
    consumer then asks the owner, and depends on it being up;
  - the **data consumers need to act without calling back** — the order's lines and total, not only
    its identifier — when they must keep working while the owner is down, or keep their own copy
    (event-carried state transfer, Fowler);
  - **business results calculated at the source** — the total, the final status — never left for
    each consumer to recompute from finer events.
- **Carry only what consumers need.** Events reach more readers than any request, and stay longer;
  personal and confidential data goes in only where a consumer needs it.

## Publishing: the outbox

A change and the message that announces it must both happen or neither: a message sent before the
commit announces a change that may roll back, and one sent after it is lost in a crash. The broker
cannot join the database's transaction (Richardson).

- **Write the message to an outbox table in the same transaction as the change.** A relay reads the
  outbox and publishes to the broker:
  - by **polling** for unsent rows — simple, with a delay set by the polling interval;
  - by **reading the database's change log** (change data capture) — a shorter delay, and more
    infrastructure to run.
- **The relay publishes at least once.** A crash after publishing and before marking the row sent
  publishes it again, so every consumer is idempotent.
- **One entity's messages leave in the order they were written**, with the entity's identifier as
  the message key (see "Ordering").
- **Published rows are removed on a schedule**; the outbox is a queue, not a history.
- **Never publish directly from a handler that also changes state** — that is the dual write the
  outbox exists to prevent.

## Consuming: the idempotent consumer

Delivery is at least once: the broker redelivers when an acknowledgment is lost, a consumer crashes
after its write, or a producer resends. Exactly-once delivery is not available end to end — a
broker's exactly-once guarantee covers only what the broker controls, never the consumer's database
or its calls to others (Microsoft). The consumer makes the second copy harmless (`design.md`
"Concurrency and idempotency").

- **Prefer an operation that is naturally safe to repeat**: set a status, upsert by identifier, apply
  a state the event carries. "The stock is now this" is safe twice; "subtract this" is not.
- **Otherwise keep an inbox** — a record of the messages the consumer has processed:
  - **the key is the message's own identifier**, set by the producer and stable across redeliveries
    — never the broker's delivery identifier, a timestamp, or a correlation identifier many messages
    share;
  - **the marker and the change commit in one transaction**; recorded apart, a crash between them
    repeats the change or loses it;
  - **a unique constraint decides**: two instances receiving the same message at once both pass a
    read-then-check, and only one insert succeeds;
  - **consumers sharing a marker store key it by consumer and message**, so one consumer's marker
    never hides the message from another;
  - **markers live as long as a copy can still arrive** — redeliveries, retry channels, and a
    dead-lettered message resent by hand much later.
- **A side effect outside the transaction** — a provider call, an email — records the key as in
  progress, calls with the same key as its idempotency key, then records the outcome; an in-progress
  record found later is settled by a reconciliation job (`modular-monolith.md` "Commands between
  modules").
- **Acknowledge after the commit**, never before: acknowledged and then crashed is a lost message.

## Ordering

- **Order is kept per key at best.** The broker keeps messages with the same key — usually the
  entity's identifier — in one ordered lane; messages with different keys have no order between
  them.
- **Order is lost** when several consumers read one lane in parallel, when a failed message is
  retried later through a retry channel, and when a dead-lettered message is resent.
- **A consumer that depends on order checks it**: each event carries the entity's version, and a
  consumer that has applied a later version ignores an earlier one — or, where a gap matters, holds
  the message until the missing one arrives or a deadline passes.
- **Design consumers not to need order** where possible: events that carry the resulting state, and
  updates that give the same result in any order.

## Failures and the dead-letter queue

A consumer's failure is handled by its kind (`modular-monolith.md` "Failure without a shared
transaction", `references/patterns/resilience.md` "Messaging"):

| Failure | Handling |
|---|---|
| transient — the database or a dependency is briefly down | redelivery with a growing delay, a bounded number of times |
| a business refusal — the stock is gone | no retry; the consumer records the outcome and publishes a failure event, and the saga compensates |
| the message cannot be processed — malformed, an unknown version, a bug | no retry beyond the bound; the dead-letter queue and an alert |

- **A message whose retries hold its lane holds everything behind it.** Where that matters, it moves
  to a retry channel with a delay, and gives up its order.
- **The dead-letter queue has an owner**, an alert on its depth, and a way to resend a message after
  the fix — through the normal path, so the consumer's idempotency still applies.
- **Dead-lettering must not lose the message.** Check what the broker guarantees in transit; some
  drop a dead-lettered message unless configured otherwise.
- **A poison message never retries forever** while the queue behind it waits.

## Sagas

A saga is one business process across modules or services, made of local transactions that each
owner commits on its own (Garcia-Molina and Salem). It takes the place of the distributed transaction
there is none of (`microservices.md` "Data").

- **Each step is one of three kinds** (Microsoft):
  - **compensable** — can be undone by a later step: reserve stock, hold an amount;
  - **the pivot** — the point of no return: once it succeeds, the saga only goes forward;
  - **retryable** — after the pivot, safe to repeat until it succeeds: send the confirmation, update
    a read model.
- **Irreversible steps come last**, after every check that can still refuse.
- **Compensation is a new business step, not a rollback.** Each step has already committed, and
  others may have seen or acted on it, so the compensation cancels its business effect: a refund for
  a charge, the reserved quantity added back — never the old value written over changes made since.
  It may differ from the original: a partial refund, a cancellation for a message already sent.
- **Compensations can fail too**: each is safe to repeat, the saga records how far it got so it can
  resume, and a compensation that keeps failing alerts a person.
- **Prefer going forward.** A transient failure is retried before anything is compensated; where the
  business would rather offer an alternative than cancel, the saga offers it or waits for a person.
- **A saga has no isolation** — other work sees its half-done state (Microsoft, Richardson). Protect
  against it with:
  - a **visible pending state** — `PendingPayment` — that other operations respect;
  - **updates that give the same result in any order**;
  - **rereading before acting**, and stopping when the data changed under the saga.
- **Every waiting step has a deadline**, and something that checks it.
- **The caller learns the outcome**: it waits for it, polls a status resource, or is notified.

## Coordinating a saga

| | Choreography | Orchestration |
|---|---|---|
| How | each participant reacts to the previous one's event and publishes its own | the service that owns the process sends each step's command and acts on the reply |
| The flow lives | nowhere — it emerges from the subscriptions | in one place: the owner's code and pending states |
| Adding a step | changes several participants | changes the owner |
| Fits | few steps; reactions in other contexts the owner does not wait for | many steps, compensation, deadlines; a process with a business owner |

- **The choice is per process, recorded with its flow in the technical specification.** A rule of
  thumb (Cui, Ruecker): orchestration inside the context that owns the process; events between
  contexts for reactions the owner does not wait for.
- **The orchestrator is the owning service, not a separate component.** It keeps the process's state
  in its own pending states, sends commands — synchronously under `modular-monolith.md` "Commands
  between modules", or as messages — and compensates on a refusal.
- **A choreography's flow is still written down** in the technical specification: the events, who
  publishes each and who reacts. A chain nobody can describe is choreography's main failure.
- **No cycles**: participants that react to each other's events in a loop.

## Event sourcing

Each change is stored as an event and the state is derived from the events, instead of storing the
current state. A decision per context or aggregate, recorded in the architecture ADR — never a side
effect of choosing CQRS or messaging (`references/patterns/application.md` "CQRS").

- **It fits** where the history is itself the requirement — a complete audit trail, a ledger,
  reconstructing past states — and the team has run event-driven systems before. **It does not fit**
  plain CRUD, reference data, short-lived systems, or views that must be consistent at once
  (Microsoft, Fowler).
- **Events record intent** — `StockReserved`, not `QuantityChanged`.
- **Stored events are never changed.** A mistake is corrected by a new, compensating event; events a
  bug wrote are compensated or transformed as they are read.
- **One stream per aggregate, appended with an optimistic concurrency check**: the append fails if
  the stream changed since it was read, and the command reloads and decides again.
- **Versioning is planned from the start**: readers ignore unknown fields and default missing ones,
  each event carries its version, and old versions are transformed to the current one as they are
  read (upcasting). Rewriting stored events is the last resort; it breaks the history the choice was
  made for.
- **Snapshots are an optimisation**, rebuildable from the stream at any time; the stream stays the
  source of truth.
- **Personal data that must be erasable** stays outside the events, referenced by identifier, or is
  encrypted with a key per person that is destroyed on erasure.
- **Read models are projections** fed by the events through idempotent handlers, and rebuilt by
  replaying them.
- **An event store is not a broker.** A broker lacks per-stream reads and the concurrency check; it
  may distribute the events, never hold them as the truth.
- **Stored events are internal**: other contexts receive integration events mapped from them.
- **Tests read as given past events, when a command, then the new events**, plus integration tests
  for projections, replays and every old event version.

## Contracts and versioning

Events are a public API that outlives any request; `microservices.md` "Contracts and versioning"
applies, and:

- **Each event's contract is written down, schema first**, in a standard format — AsyncAPI, for
  example: the channel, the payload with its types, the publisher, the consumers, the key and the
  delivery guarantee.
- **Every event carries the same envelope**: its own identifier, its source, its type, when it
  happened, and its schema version — CloudEvents, for example, where `source` and `id` together
  identify a duplicate.
- **Changes are additive** — new optional fields, new event types — and consumers ignore what they do
  not know.
- **The compatibility of a change decides the release order**: one the old consumers can read ships
  the producer first; one only the new consumers can read ships the consumers first. A schema
  registry or a contract test checks it on every change.
- **A breaking change is a new event type or version**, published beside the old one until every
  consumer has moved.
- **The schema is the contract**; event classes are never shared as a code package across services
  (`microservices.md` "Shared code").

## Observability

- **The trace context travels in the message headers** (W3C Trace Context), set when the message is
  created, so one business transaction can be followed through producers, broker and consumers.
- **Measured and alerted on**: consumer lag, the age of the oldest unsent outbox row, dead-letter
  queue depth, redeliveries, duplicates detected, and sagas past their deadline.
- **A saga's state is queryable** — the step each one is at, and why it stopped — without reading
  several services' logs.

## Testing

- **Against the real broker and database in containers** (`references/quality/testing.md`
  "Integration tests run every external dependency for real").
- **Each consumer against the second copy**: the same message twice, two copies at once, out of
  order, and a crash between the change and the acknowledgment — one effect every time.
- **The outbox**: a rolled-back change publishes nothing; a relay crash after publishing publishes
  again, harmlessly.
- **Each saga's failure paths**: a refusal at every step, the compensations, a compensation that
  fails and resumes, a step that never answers and its deadline.
- **Message contracts are consumer-driven**, as for APIs (`microservices.md` "Testing"): each
  consumer writes down the messages it reads and the fields it uses, and the producer's pipeline
  checks them.
- **The dead-letter path**: a poison message reaches the dead-letter queue, raises the alert, and can
  be resent.

## Signs of drift

Treat each as a review finding:

- a message published outside the change's transaction, with no outbox;
- a consumer with no idempotency, or its marker and its change committed apart;
- a message acknowledged before its change committed;
- domain events, entities or table rows published as integration events;
- an event one particular consumer must act on — a command in disguise;
- consumers recomputing a business result from fine-grained events;
- a consumer that assumes order across keys or across retries;
- retries without a bound, or a dead-letter queue nobody watches;
- a saga step that can be undone but has no compensation, or an irreversible step before the last
  check that can refuse;
- a choreography whose flow nobody can describe, or events that react to each other in a cycle;
- pending states with no deadline;
- stored events rewritten in place;
- a code package of event classes shared across services.
