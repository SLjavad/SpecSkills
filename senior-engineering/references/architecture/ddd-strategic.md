# Strategic Domain-Driven Design

Read when a design draws or changes the boundary of a module or service, when the system integrates
with another context or an outside system, or when one word in the domain turns out to mean two
things. Tactical design — entities, value objects, aggregates, domain events — is in
`references/design.md`; this file decides where one model ends and the next begins.

Domain-driven design (Evans) splits a large domain into parts that each have one model and one
language, and makes the relationships between those parts explicit. A boundary is a design decision,
recorded in an ADR, and it moves as the team's understanding of the domain grows.

## Contents
- Subdomains
- Bounded contexts
- Ubiquitous language
- Finding the boundaries
- Recording the contexts
- The context map
- Anti-corruption layer
- Contexts, teams and deployment
- Signs of drift
- Changing a boundary

## Subdomains

A subdomain is one part of the business problem, seen from the business side before any software
exists. Evans names three kinds:

| Kind | What it is |
|---|---|
| **Core** | why customers choose this business over another; where it must be better |
| **Supporting** | needed and specific to this business, but doing it better gains nothing |
| **Generic** | the same problem every business has, already solved |

- **The classification says where design effort pays.** What follows from it — the architecture
  style, the depth of the model, building or buying — is decided per context in the architecture
  ADR. Common choices, none of them required:
  - a core context with a rich model behind Clean Architecture (`references/architecture/clean.md`),
    the most thorough tests and the most experienced people;
  - a supporting context as vertical slices (`references/architecture/vertical-slice.md`);
  - a generic one bought or adopted as a service, behind an anti-corruption layer.
- **Finer lenses, when three kinds are too coarse**:
  - a core domain chart (DDD Crew) places each subdomain on two axes, business differentiation and
    model complexity, and names positions such as a *decisive core* — very complex and highly
    differentiating — or a *hidden core*: labelled core, but really simple data entry;
  - the evolution stage — genesis, custom-built, product, commodity — says how mature the solutions
    on the market are.
- **A classification is not permanent.** A commodity can become core, and a core capability can turn
  into a product anyone can buy; revisit it when the business strategy changes.
- **A subdomain is part of the problem; a bounded context is part of the solution.** They often map
  one to one, but a context may cover several subdomains, and a subdomain may need several models.

## Bounded contexts

- **A bounded context is the boundary inside which one model and one language apply.** Inside it,
  every term has one meaning and every rule one home. Outside it, the same word may mean something
  else; that is expected, not a defect to unify (Fowler).
- **The same real thing gets a model per context**, holding only what that context needs. The models
  share an identifier, never a class.
- **Signals that a boundary belongs here**:
  - the language changes — experts in two areas use one word differently, or two words for one thing;
  - the same thing follows different rules in different places;
  - parts change at different rates, for different reasons, or for different owners;
  - a model keeps gaining fields and flags that only one group of users cares about.
- **Not one context per entity.** A context is a business capability with its behaviour; a context
  that only stores one entity for everyone else is a database table with a network in front of it.
- **Start wide; split on evidence.** A boundary drawn too wide costs a model that is hard to keep
  consistent; one drawn too narrow costs integration between contexts that keep changing together.
  Moving a boundary inside one deployable is cheap, so split when the signals appear, not before
  (Khononov).
- **The test of a boundary** (Microsoft): few strong relationships between contexts, and typical
  operations rarely need to combine several contexts' models.

## Ubiquitous language

- **One language per context, used everywhere**: in conversation with the people who know the domain,
  in the specs, and in the code and tests — type names, method names, test names, events. A term the
  experts would not recognise in the code is a translation every reader pays for.
- **The glossary holds it.** The project keeps one glossary; a term that means different things in
  different contexts gets one entry per context — `Customer (Billing)`, `Customer (Support)` — so
  each meaning is defined once and its context is never implicit.
- **A word with two meanings inside one context** is either two contexts or a missing word. Resolve
  it: an ambiguity a conversation smooths over, the code cannot.
- **When the language changes, the code changes with it.** A rename the experts made and the code
  did not follow is drift.

## Finding the boundaries

- **Model with the people who know the domain**, not from the database schema or the organisation
  chart. The method is the team's choice — event storming, domain storytelling, a whiteboard sketch;
  the output is what counts: the contexts, the map, and a record per context.
- **Start from behaviour, not data.** Walk the business processes end to end, as the things that
  happen and the decisions made along the way. Boundaries tend to fall where the language changes,
  where work is handed from one group of people to another, and where a process waits.
- **Mark the outside systems early** — payment providers, legacy systems, partners. They shape the
  map as much as the system's own contexts.
- **Unknowns stay visible.** A question nobody can answer goes into the context's record as an open
  question, not into an assumption buried in the code.

## Recording the contexts

The contexts and the context map live in the technical specification; the architecture ADR records
the decision and points there. One short record per context, based on the Bounded Context Canvas
(DDD Crew):

| Field | Holds |
|---|---|
| Name | agreed by the team, in the domain's language |
| Purpose | why it exists, in business terms, with no technology |
| Classification | core, supporting or generic, and the reason |
| Owner | the one team that owns it |
| Messages in | the commands, queries and events it receives, and from whom |
| Messages out | the commands, queries and events it sends, and to whom |
| Language | its key terms, each an entry in the glossary |
| Business decisions | the rules and policies it owns |
| Assumptions and open questions | what the boundary rests on, and what nobody could answer yet |

## The context map

The map shows how the contexts relate: who depends on whom, and how their models meet. Map what
exists, not what is wished for; keep it small, and draw the relationships that answer a real question.

A context is **upstream** when its changes affect another, and **downstream** when it is affected.
The downstream side decides how to protect its model; the upstream side decides how much to
accommodate.

| Relationship | What it means | Use when | Avoid when |
|---|---|---|---|
| **Partnership** | the two succeed or fail together, and plan and release together | a feature needs both and their owners plan together | across separately deployed services — a lasting partnership there says they belong together |
| **Customer–supplier** | upstream plans with downstream's needs in its priorities | downstream depends on upstream changes, and upstream will schedule them | upstream answers to nobody downstream — then conformist or an anti-corruption layer |
| **Open host service** with a **published language** | upstream offers one documented, stable protocol for every consumer | several consumers need the same capability | one consumer with special needs — give it its own translator and keep the shared protocol simple |
| **Anti-corruption layer** | downstream translates the upstream model into its own | the upstream model is poor, foreign, legacy, or changes for its own reasons | the upstream model already fits — translation then costs and protects nothing |
| **Conformist** | downstream adopts the upstream model as it is | the model fits, cannot be influenced, and translating costs more than it protects | the upstream model would distort a core context |
| **Shared kernel** | a small piece of model owned jointly | a few value types that truly mean the same in both, changed only by agreement | it grows — it couples every context that shares it (`modular-monolith.md` "Shared code") |
| **Separate ways** | no integration at all | integrating costs more than it is worth, and duplication is cheaper | the duplicated part holds a business rule that must agree in both |
| **Big ball of mud** | an existing area with no clear model | never chosen — it labels what exists | — |

- **Contain a big ball of mud**: everything that talks to it goes through an anti-corruption layer,
  so its model does not spread.
- **A team that owns several contexts still draws the map.** The relationships between models matter
  even when the people are the same.

## Anti-corruption layer

The downstream context's own boundary against a model it does not want — an outside provider, a
legacy system, or another context whose model would distort its own. It is the adapter of
`references/patterns/code.md` grown to the size of a context.

- **It belongs to the downstream context** and speaks that context's language on the inside.
- **It translates everything that crosses**: names, structures, identifiers, units, states and
  errors. An upstream error becomes the downstream context's own error and never leaks as is.
- **It is the only place that knows the upstream model.** When the upstream changes, one place
  changes; when the upstream is replaced, the layer is rewritten and the context is not.
- **It may do more than map**: combine several upstream calls into one concept, cache slow reference
  data (`references/caching.md`), and apply the resilience decisions
  (`references/patterns/resilience.md`).
- **It holds no business rule** of the downstream context; those stay in its domain.
- **Replacing a legacy system piece by piece** (strangler fig): put the layer in front, move one
  capability at a time behind it, and retire the old system when nothing calls it any more.

## Contexts, teams and deployment

- **A context is the unit of a module or a service** (`references/architecture/modular-monolith.md`,
  `references/architecture/microservices.md`); how it is deployed is a separate decision. A service
  spans at most one context; one context is split across services only for a stated need, and it
  keeps one model.
- **Each context has exactly one owning team; a team may own several.** A context that needs several
  teams to change it has the wrong boundary, or the wrong teams.
- **Align ownership to the contexts deliberately.** Left alone, a system mirrors the organisation
  chart (Conway's law); draw the boundaries from the domain, then shape ownership to match.
- **Each context chooses its internal style**, recorded in the architecture ADR.

## Signs of drift

Treat each as a review finding:

- one model that every part of the system changes — a `Customer` or `Order` with fields for everyone;
- flags or type switches inside an entity for which part of the business is using it;
- one word with two meanings in one context's code, or code names the experts do not use;
- an outside system integrated without a translation layer, its names and errors spreading through
  the code;
- translation code scattered across handlers instead of one anti-corruption layer;
- a shared kernel that keeps growing;
- a context per table, or contexts that change together for most features;
- a glossary term used in more than one context with a single entry;
- a context map nobody updates, or one that shows the wished-for design instead of the real one.

## Changing a boundary

- **Merge** contexts that change together for most features, call each other for most operations, or
  share most of their language. **Split** a context whose model serves groups with different language
  and rules.
- **Each change is a superseding ADR**, with the context records and the map updated in the technical
  specification.
- **Inside one deployable, move the code first, then the data.** Across services, follow
  `microservices.md` "Merging services back" or `modular-monolith.md` "Splitting a module out".
