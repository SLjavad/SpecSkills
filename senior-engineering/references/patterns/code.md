# Code patterns

Read when a design reaches for one of these patterns, or a review finds one. You know what each
pattern is; this file says when it earns its place and how it goes wrong.
`references/principles/design.md` "Balance" governs every entry: a pattern names a present need — a
second real case, a boundary, a fake a test cannot do without — never "flexibility".

## Contents
- Composition, interfaces and inheritance
- Adapter
- Decorator
- Pipeline
- Strategy
- State
- Factory
- Builder
- Composite
- Mediator
- Observer and in-process events
- Patterns left out

## Composition, interfaces and inheritance

**Favour object composition over class inheritance** (Gamma et al., *Design Patterns*). An object gets
behaviour by holding collaborators behind interfaces it can name, not by subclassing code it then
depends on. Two kinds of "inheritance" are easy to mix up:

| | Implementing an interface | Class inheritance |
|---|---|---|
| The child receives | a contract — signatures to fulfil | the parent's code and state |
| Depends on the parent's internals | no | yes — a parent change can break every child (fragile base class) |
| Varying on two axes | pieces combine freely | one class per combination |

```
interface Channel           { send(message) }
class EmailChannel : Channel { send(message) { …email only… } }
class SmsChannel   : Channel { send(message) { …SMS only… } }
class UrgentChannel : Channel {                      // a second axis, written once, wraps any channel
    constructor(inner: Channel)
    send(message) { …priority, retry…; inner.send(message) }
}
class Notifier { constructor(channel: Channel); notify(m) { channel.send(m) } }   // no switch
```

- **Never select the variant with a switch inside the consumer.** An enum of channels switched in
  `Notifier` breaks single responsibility and open/closed; the variant is a type, chosen once at the
  composition root or in a lookup keyed by the deciding value.
- **Class inheritance is right** for a true, stable is-a, and where a framework hands you an extension
  point to override. An abstract base class with shared code or fields is class inheritance whatever
  it is named — keep it small, stateless and stable, or compose instead.
- **Languages without interfaces** follow the same rule with their own mechanism — protocols, implicit
  interfaces, function values. The test is that the child inherits no code.
- **Composition is not the Composite pattern.** Composition means *has-a*; Composite is a tree of
  same-shaped parts (below).

## Adapter

- **Problem**: your code needs a capability whose existing interface does not fit — a provider SDK, a
  legacy module, another team's library.
- **Earns its place** at every boundary to an outside system, where its model, errors or units differ
  from yours, or where tests must replace it. This is the adapter of ports and adapters
  (`references/architecture/clean.md`); against a whole other bounded context it grows into an
  anti-corruption layer (`references/architecture/ddd-strategic.md`).
- **Shape**: the target interface is yours, named for the need. The adapter translates both ways —
  arguments, results, units, and errors: a provider error becomes your error type, never leaks as is.
- **Misuse**: an interface that mirrors the provider one-to-one — the provider renamed, not adapted;
  wrapping a stable in-house library that nothing fakes and nothing will replace.
- **Simpler**: call the library directly where it is stable, yours, and never faked in a test.

## Decorator

- **Problem**: add behaviour around an operation — caching, retry, metrics, auditing, authorization —
  without editing it.
- **Earns its place** when the added behaviour is a separate concern with its own reason to change, or
  must apply to several implementations of one interface.
- **Shape**: implements the same interface, holds the inner instance, works before or after
  delegating: `CachingOrderStore(inner: OrderStore)`. The stack is composed in one place, the
  composition root, and its order is deliberate — say why caching sits outside retry, or inside.
- **Misuse**: a decorator that changes what the result means — it no longer honours the contract it
  implements; stacks so deep a reader cannot tell what runs; a decorator that patches a bug in the
  inner object instead of fixing it.
- **Simpler**: one line inside the method, where there is one implementation and the concern is
  trivial.

## Pipeline

Chain of responsibility, as most code meets it: middleware, request pipelines, handler behaviours.

- **Problem**: the same ordered steps — input validation, authorization, logging, the transaction —
  wrap many handlers.
- **Earns its place** once several handlers repeat the same steps; for one or two, the handler does
  them inline.
- **Shape**: each step receives the request and the next step, and may stop the chain — a validation
  failure returns without calling the handler. The order is declared in one place. Use the framework's
  own middleware or pipeline before building one.
- **Misuse**: a business rule in a step, hidden from anyone reading the handler; steps that depend on
  each other through a shared mutable context; a step whose effect a handler silently relies on.
- **Simpler**: the steps inline in the handler.

## Strategy

- **Problem**: one operation, several interchangeable algorithms chosen at run time — pricing per
  market, an export format, a routing rule.
- **Earns its place** once the variants are several and the branch keeps growing, or as soon as two
  variants change for different reasons or belong to different owners (`design.md` open/closed).
- **Shape**: an interface for the algorithm, one implementation per variant, and the selection in one
  place. Where the language has function values, a strategy can be a function — it needs no class.
- **Misuse**: a strategy interface with one implementation; strategies that know about each other;
  the same selection switch repeated across the code.
- **Simpler**: a branch, for two variants that change together.

## State

- **Problem**: an entity's behaviour depends on its lifecycle, and which transitions are allowed is a
  business rule.
- **Earns its place** in two steps. First, always: make the lifecycle explicit — the states, the
  allowed transitions, one guard in the entity that refuses an invalid transition loudly. Then, only
  when each state's behaviour grows substantial or the same state switch repeats across many methods:
  one object per state.
- **Misuse**: a class per state for three states and two transitions; a status changed through a
  public setter, bypassing every transition rule (`design.md` "Rich domain model").
- **Simpler**: an enumeration, a transition table and one guard method.

## Factory

- **Problem**: creating an object involves a rule — choosing the implementation, establishing
  invariants, or work a constructor must not do.
- **Earns its place** when creation chooses between implementations, needs dependencies the caller
  should not know, or can fail as a business outcome: a static factory on the entity —
  `Order.create(…)` returning the order or the reason it cannot exist.
- **Misuse**: a factory that only calls the constructor; an abstract factory with one family of
  products; a factory that pulls objects out of the dependency-injection container — a service
  locator under another name.
- **Simpler**: the constructor.

## Builder

- **Problem**: assembling an object with many optional parts, or in several steps.
- **Earns its place** above all in tests: a test-data builder with valid defaults, so each test names
  only the values it is about. Also for complex immutable configuration.
- **Misuse**: a builder that creates a domain entity without going through its constructor or factory,
  so invariants are skipped; a builder for an object with three required arguments.
- **Simpler**: named or optional arguments; copy-with-changes on an immutable record.

## Composite

- **Problem**: a tree in which single items and groups must be treated the same — a folder of files
  and folders, a price built from component prices, rules nested in rules.
- **Earns its place** only when the structure is genuinely recursive and callers genuinely want one
  interface for a leaf and a group.
- **Misuse**: operations that make sense for only one of the two, implemented on the other by
  throwing "not supported"; a composite where a flat list would do.
- **Simpler**: a list.

## Mediator

Two different things carry the name.

- **Coordinating peers** (*Design Patterns*): one object runs the interaction among a set of
  collaborators that would otherwise all reference each other — the controls of one form, the steps
  of one workflow. Earns its place where the peer-to-peer coupling is many-to-many. Its failure mode is
  growing into a god object that knows everything.
- **An in-process request dispatcher**: the caller sends a command and a dispatcher finds its handler.
  It decouples entry points from handlers and hosts a pipeline. Its cost is indirection — a reader
  cannot step from the call site to the handler — and everything still runs in one process.
  - Misuse: a handler sending another command through the dispatcher — a handler calling a handler,
    with the coupling hidden; in-process notifications used where a reaction needs isolation and
    retry (see Observer).
  - Simpler: inject the handler where it is called, and wrap it with decorators for the pipeline.
- The dispatcher library, if any, is the stack playbook's choice, not this file's.

## Observer and in-process events

- **Problem**: other parts of the system must react to a change, and the source should not know them.
- **Earns its place** when the reactions belong to other features or modules and vary independently
  of the change itself.
- **Shape**: the entity raises a domain event; a dispatcher delivers it to handlers. Decide, and
  state, when it is dispatched:
  - inside the transaction — all or nothing, but a failing reaction fails the change;
  - after the commit — the change stands, and a reaction can be lost unless the event goes through an
    outbox (`references/architecture/event-driven.md`).
- **Misuse**: in-process handlers with outside side effects — email, HTTP — run in the same call: when
  one fails and the call is retried, the ones that succeeded run again. Those reactions go out of
  process. Also: chains of events nobody can follow; an event where a direct call is the honest
  dependency — one known reaction, in the same module.
- **Simpler**: a direct method call.

## Patterns left out

- **Singleton** — a dependency-injection lifetime; a hand-written one is global mutable state.
- **Service locator** — an anti-pattern: dependencies are declared and injected, never fetched.
- **Template method** — composition instead: pass the varying step in as a strategy.
- **Proxy** — mostly a decorator; lazy loading belongs to the ORM.
- **Facade** — a module's public contract (`references/architecture/modular-monolith.md`).
- **Command objects** — the commands of a use case (`references/patterns/application.md`).
- **Abstract factory, bridge, prototype, flyweight, visitor, memento, interpreter** — rarely the
  answer in application code. When one seems to be, research it for the case at hand and record the
  choice in an ADR.
