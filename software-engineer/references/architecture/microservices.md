# Microservices

Read when the project's architecture ADR chose microservices, when a module is about to be split out
of a monolith, or when a design adds, merges or changes a service boundary. It adds the rules of
distribution to `references/architecture/modular-monolith.md`, whose boundary rules apply here too —
a service is a module that is deployed, scaled and failed on its own. Inside a service, its own style
applies (`references/architecture/clean.md`, `references/architecture/vertical-slice.md`).

## Contents
- When it fits
- Service boundaries
- Independent deployability
- Data
- Communication
- Contracts and versioning
- The edge
- Security between services
- Observability
- Shared code
- Testing
- Signs of drift
- Merging services back

## When it fits

Microservices trade simple development and operation for independent deployment and scaling. The
trade is worth it only for a present, stated need, recorded in the architecture ADR:

- **parts that must release on their own schedule** — one that changes daily beside one that changes
  rarely, or parts owned by different teams;
- **parts with very different scaling, availability or isolation needs** — a spiky public search
  beside a steady back office, a payment component under stricter compliance;
- **a part that needs a different technology** for a real reason.

Without one of these, choose a modular monolith (Fowler, *Monolith First*). With one, the
prerequisites come first, or every service multiplies their absence (Fowler, *Microservice
Prerequisites*): automated provisioning, an automated deployment pipeline per service, monitoring of
both technical and business signals, and teams that operate what they build.

- **Split along boundaries that already proved themselves** as modules. A service boundary is
  expensive to move; a module boundary is cheap.
- **A team that cannot keep a monolith modular** will build a distributed big ball of mud — every
  monolith problem, plus the network (Brown).

## Service boundaries

- **A service is a business capability, inside one bounded context**
  (`references/architecture/ddd-strategic.md`). Not an entity — a `CustomerService` that only stores
  customers for everyone else is a remote database table.
- **Each service has exactly one owning team**, which builds and runs it; a service two teams share
  has no owner. A team may own several services, and each split it makes has its own reason from
  "When it fits" — every service adds a pipeline, a deployment and a network boundary to run
  (Richardson, *Service per team*).
- **Size follows the team and the change, not the line count.** What changes together deploys
  together; a feature that routinely needs coordinated changes in several services shows a boundary
  in the wrong place.
- **Chatty communication between two services** — many calls for one operation — is a sign that they
  belong together, or that one holds data the other needs locally.

## Independent deployability

The defining property: any service can be released without releasing another (Newman).

- **Hide everything that is not the contract** — the schema, the model, the internal endpoints. What
  is hidden can change freely; what is shared can only change carefully.
- **Every change is backward compatible** with the consumers in production, so services deploy in any
  order. A breaking change goes expand–migrate–contract: add the new, move the consumers, then remove
  the old.
- **Lockstep releases are a defect** — "deploy these three together" means three services with one
  boundary.
- **Each service has its own pipeline, its own configuration from the environment**, and can be
  rolled back on its own.

## Data

- **By default each service owns its data** — its own database, or its own schema on a shared
  server — and no other service reads or writes it (`modular-monolith.md` "Data ownership"). Sharing a
  database server is a cost decision and couples nothing; sharing tables is what couples.
- **Sharing tables between services is a trade-off recorded in an ADR.** It buys local transactions
  and joins; it costs schema changes coordinated across services, locks one service holds that block
  another, and one store for every access pattern (Richardson, *Shared database*). Where it is chosen:
  - each shared table has one owning service, which alone writes it and changes its schema; the
    others read it through a view or a read-only grant;
  - its schema changes go expand–migrate–contract across every service that reads it, so no release
    waits for another.
- **Queries across services** use API composition — the caller or a composing service asks each owner
  — or a local read model built from the owners' events. Duplicated data is the price of autonomy, and
  it is accepted: refusing every copy forces synchronous calls everywhere.
- **No distributed transactions.** A change across services is a sequence of local transactions —
  synchronous commands under the rules in "Communication", or events through an outbox — with a saga
  and compensations where many steps must all complete (`references/architecture/event-driven.md`).
- **A service with its own database picks its store** for its own access pattern, within the
  platform's supported set.

## Communication

- **Synchronous calls use a request–response protocol** — HTTP or gRPC, for example; a stack
  decision. The caller waits for the answer, whether or not its code uses asynchronous I/O, so the
  other service must be up. Every call follows `references/patterns/resilience.md` — timeout,
  bounded retry, breaker, a decided answer when the owner is down — and passes its deadline on.
- **Asynchronous messages go through a broker** — RabbitMQ, Kafka or the platform's own, a stack
  decision. The receiver may be down when a message is sent, and catches up later.
- **Queries and commands may both be synchronous.** A command follows `modular-monolith.md`
  "Commands between modules": an idempotency key, a pending state committed before the call, a
  reconciliation job. Over the network a timeout is the usual unknown outcome — the command may or may
  not have run — and only the key makes resending it safe; a command without one is never retried.
- **A service answering a query answers from its own data**; it does not call another service for
  data to produce that answer. A chain adds every hop's latency and fails when any hop fails. When
  one response needs several services' data:
  - a composer — a backend-for-frontend, an aggregator or the client — calls them in parallel and
    merges the answers, returning what it has when an optional part fails;
  - data read on every request is kept as a local copy fed by the owner's events instead;
  - a chain that cannot be avoided is recorded in an ADR, kept short, and passes its deadline down.
- **Events are business facts** — `OrderCancelled`, with the data a consumer needs — not database
  entities, not change-data dumps, not generic "entity updated" messages. Each is self-contained and
  does not depend on the order of other events unless the contract says so.
- **The broker carries messages, not logic** — smart endpoints, dumb pipes (Lewis and Fowler).

## Contracts and versioning

- **Contracts are written down, schema first** — the API and the events, in a standard format the
  stack supports — and published where consumers find them.
- **Consumers read tolerantly**: ignore unknown fields, never depend on field order. Producers change
  additively: new optional fields, new endpoints, new event types.
- **A breaking change is a new version**, run side by side with the old one until the consumers have
  moved, with the removal date announced.
- **The contract is shared as a schema, not as a shared code package of domain types.**

## The edge

- **External clients reach services through a gateway** — routing, authentication of the caller,
  rate limiting, TLS termination — never by calling internal services directly.
- **The gateway holds no business rule.** Domain logic in the gateway couples every service to it.
- **A backend-for-frontend** per kind of client, where clients need very different shapes, composes
  the services' APIs for that client and is owned by the client's team.

## Security between services

- **Services authenticate each other** — mutual TLS, workload identities or signed service tokens —
  and the network is not trusted because it is internal.
- **The gateway validates the caller's token; each service authorizes its own operations** — may this
  caller cancel this order — because only the service knows the rule, and a call that bypasses the
  gateway must not bypass the rule.
- **The identity reaches the service in a form it can verify** — the caller's token passed on where
  its audience includes the service, or an internal token the gateway issues in exchange, checked
  locally against the issuer's keys — never a plain header any caller inside the network could set.
  A service that cannot verify it refuses the request.
- **Each service holds only its own secrets and permissions** — its database credentials, its queue
  access — so one compromised service does not open the others.

## Observability

- **Every request carries a trace context** propagated across every call and message (W3C Trace
  Context), and every log line carries the trace and correlation identifiers.
- **Logs, metrics and traces are collected centrally**; a failure that crosses services is
  undiagnosable from one service's logs.
- **Monitor business signals too** — orders per minute, payments failing — because a distributed
  system can be technically healthy and still not doing its job.

## Shared code

- **Technical libraries** — logging setup, tracing, the outbox — may be shared as versioned
  packages, upgraded by each service on its own schedule, never forcing a coordinated release.
- **Never a shared domain library.** Shared domain types couple every service's model and release;
  a shared kernel of value types stays inside one deployable (`modular-monolith.md` "Shared code").
- **Limit the stack deliberately** — a few supported languages, one way to log, trace and deploy —
  so autonomy does not become a dozen ways of doing the same thing.

## Testing

- **Service tests carry most of the weight**: each service through its API, with its own database and
  broker in containers (`references/quality/testing.md`), and the services it calls replaced by stubs
  at the network boundary.
- **Consumer-driven contract tests**: each consumer writes down the requests it sends and the fields
  it reads from each answer; the provider's pipeline checks every consumer's contract against the
  provider on each change. A change that breaks a consumer fails the provider's build before it
  deploys, and a field no consumer reads can change freely.
- **A few end-to-end tests** across deployed services, for the critical journeys only; a large
  end-to-end suite is slow, flaky and brings back lockstep releases.
- **Fault injection**: the resilience decisions are tested with the dependency slow, failing or gone
  (`resilience.md` "Testing and observing").

## Signs of drift

Treat each as a review finding — together they make a distributed monolith:

- services that must be deployed together, or a release train across services;
- tables shared between services without an ADR, or written by more than one service;
- a chain of synchronous calls on the request path, or one call per item in a loop;
- a shared domain library, or contracts that expose a service's entities;
- entity services that every other service calls for its data;
- business rules in the gateway or in the broker;
- a command sent without an idempotency key, or while the caller's transaction is open;
- a failure that needs several teams' logs to diagnose, because trace context is missing.

## Merging services back

When two services always change together, are always deployed together, or call each other for most
operations, merge them — a superseding ADR, one deployment, one database with two modules. Fewer,
cohesive services beat many coupled ones; merging is a correction, not a failure.
