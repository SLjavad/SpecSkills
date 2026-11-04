# Clean Architecture

Read when the project's architecture ADR chose Clean Architecture — for the whole system, or for one
module of a modular monolith. It adds the rules of this style to `references/design.md`, which still
applies in full: the dependency rule, the rich domain model, failure design and balance.

Clean Architecture (Robert C. Martin) shares its core with Hexagonal (ports and adapters) and Onion:
policy at the centre, mechanism outside, every dependency pointing inward. This file uses Clean's
vocabulary; a project that says "hexagonal" follows the same rules under other names.

## Contents
- When it fits
- The rings
- The dependency rule in practice
- Use cases
- Validation and authorization
- Persistence
- Mapping between rings
- Errors
- Lighter boundaries
- Testing
- Signs of drift
- Moving a module in or out

## When it fits

Choose it where the business rules are complex and long-lived and must be testable without the
database, the web framework or any outside system — several adapters for one core, external systems
that will change, several teams on one codebase. It costs a ring of ports and adapters around every
use case, and that cost is wasted on a module of plain data entry.

- **CRUD, reporting, admin lookups, a short-lived tool** — vertical slices or one well-organised
  project, not Clean. A Clean core with four projects and a request pipeline for six endpoints is
  over-engineering, a defect by `design.md` "Balance".
- **Per module, not per system.** In a modular monolith the core domain can be Clean while a
  supporting module is slices; the architecture ADR records each module's style.

## The rings

Martin draws four circles and says they are schematic: the count is not the rule, the direction is.
The project's ADR fixes which rings exist; add none it did not choose. The common form:

| Ring | Holds | Depends on | Never contains |
|---|---|---|---|
| **Domain** | entities, value objects, domain events, domain services, domain errors | nothing but the language and pure libraries | a framework, ORM or serializer type; any I/O |
| **Application** | one handler per use case, its command or query, the ports it needs, application errors | Domain | an HTTP, ORM or vendor SDK type |
| **Adapters** | endpoints and controllers, presenters, port implementations — persistence, gateways, message publishers and consumers — and their mapping | Application, Domain | business rules |
| **Composition root** | the host's startup: configuration and the wiring of every port to its adapter | everything | anything else |

- **Adapters come in two kinds**: driving (the web endpoint, the message consumer, the scheduled job —
  they call a use case) and driven (the database, the payment provider, the clock — a use case calls
  them through a port). Both sit outside; neither knows the other.
- **Split the adapters by concern** — persistence, messaging, email, each external system — once one
  adapter package would pull in unrelated dependencies. One "infrastructure" package that references
  every library makes every change rebuild and redeploy everything.
- **No shared "common" package that everything references.** It becomes the place where a framework
  type slips into the domain. What the domain needs, the domain owns.

## The dependency rule in practice

- **Source dependencies point inward; control flow does not have to.** A use case that must reach the
  database calls a port it owns, and the persistence adapter implements that port: the call goes
  outward, the dependency points inward.
- **A port lives with the code that needs it and is named for the need** — `BookingStore`,
  `PaymentGateway`, `Clock` — not for a technology. The technology names the adapter.
- **Nothing outer crosses inward in its own format.** No request object, ORM entity or provider DTO
  enters a use case; the adapter converts it to the command, or to a type the domain owns.
- **Only the composition root knows everything.** Where the host must reference the adapters to wire
  them, that reference is used in the root and nowhere else — an endpoint never constructs an adapter.
- **The check, as a thought experiment**: take the web adapter and the persistence adapter, with their
  framework and driver packages, out of the build. The domain and the application must still compile
  and their tests still run; every error that would appear is a dependency pointing outward — a
  handler taking the web framework's request type, an ORM attribute on an entity. The architecture
  tests run this check on every build.

## Use cases

- **One use case is one operation in the domain's language** — `CancelBooking`, `IssueRefund` — not
  create/read/update/delete on a table. The application ring's top level lists the use cases, grouped
  by feature, so the structure says what the system does ("screaming architecture"); a top level of
  `Services/`, `Helpers/` and `Models/` says only how it is built.
- **Each feature keeps its command, handler and input validation together**, in one folder.
- **A handler orchestrates and does not decide**: authorize, load, call domain behaviour, save,
  publish. A business rule in a handler is in the wrong ring (`design.md` "Rich domain model").
- **Input is a command or query of plain data; output is a plain result.** The driving adapter maps
  the result to its delivery format. Martin's output port and presenter earn their place only where
  one use case serves several delivery formats that shape the result differently; otherwise return
  the result.
- **One use case, one transaction.** The handler, or the pipeline around it, commits once; a port
  never commits behind the use case's back.
- **A handler never calls another handler.** Logic two use cases share belongs in the domain — an
  entity method or a domain service — and an operation that needs both runs as one use case.
- **Cross-cutting steps** — input validation, authorization, logging, the transaction — wrap the
  handlers as a pipeline once several handlers repeat them (`references/patterns/code.md`); for one
  or two use cases, the handler does it inline.

## Validation and authorization

Each kind of check has one home:

- **Input shape** — required fields, lengths, formats: the use case's input validation, reporting
  every problem at once, before any domain object is touched.
- **Invariants**: the domain, always, even when input validation already checked the same thing — an
  entity cannot be invalid (`design.md`).
- **Rules that need data** — uniqueness, existence, limits across records: the use case, through a
  port, and backed by a database constraint, since a read-then-write check is a race (`design.md`
  "Concurrency and idempotency").
- **Authentication** at the driving adapter; **authorization** of the operation — may this caller
  cancel this booking — in the use case, where it cannot be bypassed by a second entry point.

## Persistence

- **The domain does not reference the ORM.** Mapping lives in the persistence adapter, as the ORM's
  external configuration; no persistence or serialization attributes on domain types.
- **Choose one write-side port per project, and record it in the ADR:**
  - a repository per aggregate root, loading and saving the whole aggregate — the default;
  - or a data-context port the application owns, over the ORM — fewer classes, but the ORM's query
    semantics leak into the use cases, and the application references the ORM's package. Acceptable
    when the ADR says so and the ORM is not expected to change; the ORM package is then the one
    outward reference the application may have, and the architecture tests allow exactly that one.
- **No generic repository, and no repository for a non-aggregate.** A repository that hands out a
  composable query object leaks the ORM through the port; it returns aggregates or plain results.
- **Reads bypass the aggregates.** A query projects straight from the store into its result type
  through a read port; loading aggregates to return a DTO pays for invariants nobody changes.
- **Don't wrap the ORM's unit of work in another one.** The port exposes one way to commit.

## Mapping between rings

Map where two rings truly need different shapes, and nowhere else — a model and a mapper at every
boundary for every operation is the most common Clean over-engineering.

- **The command and query are the input DTOs**; no separate request model for the use case.
- **The persistence mapping is the ORM's configuration** of the domain types; a separate persistence
  model only where the ORM cannot map the domain's private state (`design.md`).
- **Queries project directly into their response model.**
- **An API contract is never a domain type, and a domain type is never an API contract** — that one
  mapping always stays, because the contract must not change when the domain does.

## Errors

The domain fails fast on a broken invariant and returns a typed result for an expected business
outcome (`design.md`, one error convention). The driving adapter translates both into its delivery
format — a status code, a problem response, a rejected message. The domain and the use cases never
know a status code.

## Lighter boundaries

A full boundary — separate compiled packages for each ring — lets the compiler enforce the direction,
and costs build structure and ceremony. Martin describes partial boundaries for where the separation is
wanted but the full cost is not yet earned. Two that hold up:

- **One package, rings as folders**, with the direction enforced by architecture tests instead of the
  compiler — usual for a small Clean module.
- **Separate packages only where a ring is shared or deployed differently**, or where the team has
  already seen the tests ignored.

Record which one the module uses in the ADR; either is Clean, neither is "Clean but lighter".

## Testing

- **Domain**: unit tests on entities and value objects — no doubles, because nothing there does I/O.
- **Use cases**: tests through the handler with the ports faked, for the decisions and the
  orchestration.
- **Adapters**: integration tests against the real dependency in a container (`references/testing.md`)
  — the mapping, the queries, the constraints are exactly what a fake hides.
- **End to end**: a few through the driving adapter, for the wiring.
- **Architecture tests** for this style, failing the build (`design.md` "Enforce the structure"):
  - the domain references nothing outside the language and approved pure libraries;
  - the application references the domain only;
  - no web, ORM or vendor SDK type in the domain or the application;
  - driving adapters do not reference driven adapters — only the composition root does;
  - no cycles between features in the application ring.

## Signs of drift

Treat each as a review finding:

- an entity with public setters and its rules in handlers — the anemic model;
- persistence or serialization attributes on a domain type;
- the application ring referencing an adapter, or a shared package that pulls a framework inward;
- an interface for something that is neither a boundary nor faked in a test — a string helper, a
  mapper, an id generator with one implementation;
- a generic repository, or a repository returning a composable query;
- a service whose methods only forward to a repository — a layer whose job is forwarding;
- a handler calling another handler;
- a model and a mapper at every boundary for a simple operation;
- aggregates loaded to answer a read;
- a top-level structure of technical folders instead of features.

## Moving a module in or out

- **Into Clean**, when a module's rules outgrow slices: push the rules into entities first, then put
  ports in front of the dependencies the use cases call, then move the adapter code outward — one
  feature at a time, with architecture tests baselined on what has not moved yet.
- **Out of Clean**, when a module turns out to be plain data: a superseding ADR, then collapse the
  ports that no longer serve a boundary.
