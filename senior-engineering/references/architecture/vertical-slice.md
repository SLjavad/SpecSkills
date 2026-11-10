# Vertical Slice Architecture

Read when the project's architecture ADR chose vertical slices — for the whole system, or for one
module of a modular monolith. It adds the rules of this style to `references/principles/design.md`,
which still applies in full: the rich domain model, failure design and balance.

Vertical slices (Jimmy Bogard) organise code by request instead of by technical layer: each feature
holds everything from its entry point to its data access, and coupling runs along the axis of change —
high inside a slice, low between slices.

## Contents
- When it fits
- The slice
- Domain logic inside a slice
- Sharing
- Duplication
- A slice never calls a slice
- Data access
- Testing
- Signs of drift
- Moving a module in or out

## When it fits

- **Many independent requests** whose logic varies from plain data entry to real rules — the style lets
  each request choose its own depth instead of paying one architecture's ceremony everywhere.
- **CRUD-heavy and reporting modules**, admin tools, integrations with little domain logic.
- **A team that recognises code smells and refactors on them.** The style starts simple and relies on
  the team to move logic into the domain when it grows; Bogard says plainly that a team which cannot
  tell when a handler does too much should not use it.
- **Per module, not per system.** In a modular monolith a supporting module can be slices while the
  core domain is Clean (`references/architecture/clean.md`); the architecture ADR records each
  module's style.
- **Not the right choice** where the business rules are complex, long-lived and must be testable
  without any outside system, or where several adapters drive one core — that is Clean's ground.

## The slice

- **One request, one folder**: the command or query, its handler, its input validation, its data access
  and its endpoint or message consumer, together. The folder tree lists what the system does,
  grouped by feature — `Orders/CancelOrder/`, `Orders/ChangeDeliveryDate/` — never `Controllers/`,
  `Services/`, `Repositories/`.
- **Commands and queries are separate slices** (`references/patterns/application.md` "Commands and
  queries"); a slice that reads and writes is two slices.
- **Adding a feature adds a slice**; it does not edit a shared service. A change to one request touches
  one folder, and its side effects are limited to that folder and the domain types it calls.
- **The handler orchestrates**: authorize, load, call domain behaviour, save, respond. Cross-cutting
  steps — validation, logging, the transaction — wrap the handlers as a pipeline once several repeat
  them (`references/patterns/code.md` "Pipeline").

## Domain logic inside a slice

Each slice chooses how much design it needs, but the baseline is the rich domain model (`design.md`):

- **Start as a transaction script** — the handler reads, changes and saves — while the request has no
  rule to protect.
- **Move the rule into the entity as soon as one appears** — an invariant, a state transition, a
  calculation the business names. Do not skip this refactor: a rule left in a handler is the anemic
  model the style is often blamed for.
- **A slice stays a plain transaction script only when there is no invariant**, and that
  classification is recorded with its reason, as `design.md` requires for plain CRUD.
- **Value objects and domain services** come in on the same need test as in any style (`design.md`
  "Rich domain model").

## Sharing

Vertical slices do not mean share nothing. What decides is what is shared and how much coupling it
creates (Comartin):

| Kind of code | Where it lives | Rule |
|---|---|---|
| **Technical plumbing** — logging, the request pipeline, the result type, the outbox | one shared infrastructure folder or package | shared freely; it holds no business rule |
| **The domain model** — entities, value objects, domain services | the module's domain folder | shared by every slice that works on the same thing; each rule exists once |
| **Feature-level helpers** used by related slices only | a shared folder inside that feature | never used from another feature |
| **A `Common` or `Utils` package** | nowhere | it couples unrelated features through whatever lands in it |

- **Slices share the entity, not the handler.** `CancelOrder` and `ChangeDeliveryDate` both call
  `Order`, whose `ensureChangeable` rule exists once; each handler keeps its own flow, data access and
  response.
- **Share a model only within one module and one meaning.** When another feature needs the same data
  for a different purpose — shipping needs an order's address, not its cancellation rules — it gets
  its own model. One entity that every feature in the system changes is a god object
  (`references/architecture/ddd-strategic.md`).
- **A slice owns the data it writes.** Two unrelated slices changing the same state through different
  paths is the coupling the style exists to prevent; the state changes through the entity's
  behaviour.

## Duplication

- **A business rule is never duplicated.** The moment a second slice needs it, it moves into the entity
  or a domain service.
- **Other code — mapping, formatting, query fragments — may be duplicated** until it is repeated,
  identical in every copy, and stable. Extract before that and the next case differs slightly, so the
  helper grows flags and becomes the wrong abstraction, which costs more than the copies did.
- **Code that only looks alike is not duplication.** A list's summary and a page's details share
  fields but change for different consumers; merging them couples two screens.

## A slice never calls a slice

A handler calling another slice's handler hides one use case inside another and couples their
changes. Instead:

- **Shared rules** go to the domain, which both slices call.
- **A reaction in another feature** — update the customer's order history after an order is placed
  — is a domain event the other feature handles (`references/patterns/code.md` "Observer and
  in-process events"); one with an outside side effect, such as sending the confirmation, leaves
  through an outbox.
- **An operation of another module** goes through that module's public contract
  (`references/architecture/modular-monolith.md`), never through its slices.
- **One operation that needs both** is one slice that calls the domain for both.

## Data access

- **By default the handler uses its data access directly** — the second shape in
  `references/patterns/application.md` "Choosing the persistence shape". A repository or another
  interface over it needs its own reason: an aggregate's loading rules that deserve one home, or a
  fake a test cannot do without.
- **Queries project straight into their response** and select only what they return; a query slice
  may use hand-written SQL (`application.md` "The read side").
- **Entities are mapped through the ORM's external configuration**, keeping the domain free of
  persistence attributes, even though the handler references the ORM (`design.md`).
- **One slice, one commit** (`application.md` "Unit of work").

## Testing

- **Slice tests carry most of the weight**: through the slice's entry point, against the real database
  and dependencies in containers (`references/quality/testing.md`) — they prove the request, the
  validation, the query and the response together, without mocking the layers a slice does not have.
- **Domain unit tests** for every entity and value object that carries a rule — fast, with no doubles.
- **Architecture tests**, failing the build
  (`design.md` "Enforce the structure with architecture tests"):
  - a slice does not reference another slice's types;
  - features do not reference each other except through the domain, events or a module contract;
  - no `Common` or `Utils` package exists;
  - the domain references no framework, ORM or serializer type.

## Signs of drift

Treat each as a review finding:

- business rules accumulating in handlers — the anemic model coming back;
- the same rule copied into several slices, with the copies starting to differ;
- a handler calling another slice's handler, or sending another slice's command;
- a shared folder that keeps growing, or a `Common` package;
- one entity that every feature in the system changes;
- a "service" class shared by many slices — layers returning under another name;
- interfaces over the data access with one implementation and no test that fakes them.

## Moving a module in or out

- **Into Clean**, when a module's rules outgrow slices — several driving adapters, rules that must be
  tested without the database, outside systems that will change: push the rules into entities first,
  then put ports in front of the dependencies the handlers call, then move the adapter code outward,
  one feature at a time (`references/architecture/clean.md` "Moving a module in or out").
- **Out of Clean into slices**, when a Clean module turns out to be plain data: a superseding ADR,
  then collapse the ports that serve no boundary and fold each use case into its slice.
