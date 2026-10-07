# Code review lenses

How to judge code — your own before reporting, or anyone's on request. spec-driven's review phase runs
these lenses too, after checking the code against the spec.

## Contents
- Process
- Lens: correctness
- Lens: design principles
- Lens: domain model
- Lens: dependencies in the code
- Lens: package dependencies
- Lens: algorithms and efficiency
- Lens: security, tests, readability
- Writing findings
- Improvements are proposals

## Process

1. **Understand the change and its intent** before judging it. Get its blast radius from the code graph
   where the project has one: what calls the changed code, and what it reaches.
2. **Run the automated gates first** — build, tests, analyzers, and a dependency audit when the change
   touches dependencies. Do not spend review attention on what a tool already enforces, and name any
   gate that did not run.
3. **Run the lenses at the scale of the change** — beyond a local change, as separate passes or
   parallel sub-reviews where the tooling allows and the user agrees, so one concern does not crowd out
   the others. The
   lenses below are the minimum; add whatever further lens the change calls for — data migration,
   accessibility, operability, compatibility, and so on.
4. **Verify every candidate finding** against the code before reporting it — reproduce it, trace it, or
   measure it. Drop what does not survive; merge duplicates across lenses.
5. **Rank the result**: blocking first, then non-blocking, with problems that pre-date the change
   reported separately from the ones it introduced.

## Lens: correctness

The rules and algorithms against their worked examples. The edge cases: empty, zero, one, maximum,
tie, absent, negative, overflow. Off-by-one, rounding direction, null handling, ordering, tie-breaks,
time zones. Every failure branch reachable, and handled the way the spec says.

## Lens: design principles

Judge the code against **the project's declared principles first** — the rules in `AGENTS.md`, the
area records and the ADRs that set conventions — and then against SOLID, DRY and KISS/YAGNI. The set
is small on purpose (`design.md`): do not review against principles beyond it, because each one added
is another push toward layers and abstraction.

Raise a finding only with a concrete change scenario or defect risk — "could be cleaner" or "violates
principle X" on its own is not a finding. **Over-engineering is a finding with the same weight as a
violation:** an abstraction, layer, interface or pattern with no present need behind it, a generic
mechanism for one case, a chain of forwarding hops between the entry point and the decision. When
principles pull apart, the simpler design wins.

| Principle | Signals |
|---|---|
| Single responsibility | the file changes in history for unrelated reasons; a long list of injected dependencies or props; one unit that fetches, decides and renders |
| Open/closed | the same `switch` or `if` chain on a type or kind in three or more places, growing with each variant |
| Liskov | overrides that throw "not supported" when the contract does not advertise the capability; callers downcasting; subtypes with stricter preconditions |
| Interface segregation | implementers stubbing members; callers using a small slice of a wide interface or props object |
| Dependency inversion | domain or application code constructing database, HTTP, clock or environment objects; UI components calling API clients directly |
| DRY — one source for each piece of knowledge | the same rule or constant decided in two places; but merge only true duplication, at the third occurrence, never coincidental similarity |
| KISS and YAGNI | machinery with no requirement behind it; configuration nobody sets; a generic framework for one case; an interface with one implementation and no test that needs to fake it |

Layering and module boundaries are not weighed here as principles: they are the project's chosen
architecture, checked by its architecture tests and by the dependency lens below.

Finally the entry-point test from `design.md`: read down from the entry point; four hops to the
decision is over-fragmented, five unrelated things at once is under-decomposed.

## Lens: domain model

Anemic signals: public setters on state that carries an invariant; services named *Manager* or
*Helper* holding `if (x.Status == …) x.Status = …`; the same validation repeated across handlers;
invariants checked in controllers or components; collections exposed mutable. Each is a finding
against the rich-domain rules in `design.md` — unless the module is classified as plain CRUD there.

## Lens: dependencies in the code

- Layer violations against the project's chosen architecture, cycles, units with very high fan-out,
  dead code, and unused parameters, imports and exports.
- **Fan-in is a note, not a finding.** A type used everywhere — the one definition of money — is doing
  its job; high fan-in only says a change there needs care and tests. Do not score modules on
  stability or abstractness either: the remedy those metrics suggest is more interfaces.
- Use the code graph: changed-symbol detection, call tracing for reachability and blast radius, degree
  filters for fan-out, architecture views for cycles and layers.
- **Confirm anything "unused" or "dead" with a text search before reporting it.** Dependency injection,
  reflection, routing conventions, serialization and lazy loading make graph and analyzer results
  wrong in both directions. Check that the index covers the path.
- A violation that will recur belongs in an architecture test, not in the next review.

## Lens: package dependencies

When the change adds, removes or upgrades a package, or on request: known-vulnerable (transitive
included), outdated, deprecated, archived or unmaintained, unused or
redundant (two libraries doing one job), version drift between projects, licence changes, and runtimes
near end of support. Use the stack's audit and outdated-package commands and record their output. An
upgrade or removal is a proposal, like any other change.

## Lens: algorithms and efficiency

Every finding here carries evidence — a measurement, a query plan, or a complexity estimate at the
realistic size the spec states.

- Complexity at realistic N: nested scans, and lookups or sorts inside loops. Small N rarely matters.
- Data access: N+1 queries, unbounded result sets, over-fetching, cartesian explosions, and missing
  indexes for the queries actually issued.
- Lazy sequences enumerated twice; blocking on asynchronous work; lock contention on common paths.
- Hot-path allocation: boxing, large temporary buffers, serializer or option objects rebuilt per call,
  strings built in loops, expensive log arguments evaluated when the level is off.
- Exceptions used for control flow on hot paths.
- Regular expressions on untrusted input with a backtracking engine and no timeout.
- UI: derived state synchronized through side effects (React effects, for example), re-render storms,
  slow interactions.

## Lens: security, tests, readability

- **Security** — the audit checklist in `security.md`, in every review, not only when asked.
- **Tests** — `testing.md`: the four lenses covered for significant flows, and the flow's other risks —
  concurrency, idempotency, resilience and whatever else it carries; tests that cannot fail, mirror the
  implementation, or were weakened; mutation score on the core; Testcontainers wherever an external
  dependency is touched.
- **Readability and leftovers** — misleading names, clever lines, debug output, commented-out code,
  stray `TODO`s, scaffolding, dead abstractions.

## Writing findings

- **No finding without a consequence**: the input, state or sequence that produces a wrong result, or
  the specific thing a reader will misunderstand. Otherwise it is a note — and notes stay few, or they
  train the reader to skim.
- **Label each one**: blocking or non-blocking, and introduced by this change or already there.
- **Do not manufacture findings.** A reviewer told to find problems finds some, and fixing invented ones
  breeds over-engineering. A clean review is a valid outcome — say exactly what you checked.
- **Suggest the smallest fix**, not a rewrite of the area.

## Improvements are proposals

Anything beyond fixing a defect — an optimization, a refactor, an upgrade, a better pattern — is
**proposed, never applied**, and waits for the user's approval:

```markdown
### P-NNN — <title>
Status: idea | proposed | accepted | rejected | deferred | withdrawn | implemented | superseded
Raised: YYYY-MM-DD by <agent/role> · Type: product | architecture | optimization | refactor | dependency | process
Where: <file / symbol> · Found by: <lens>   (optimization or refactor only)
Problem and evidence: <measurement or estimate; data size; environment; tool; the cause>
Proposal: <the minimal change> · Alternatives: <…, including doing nothing>
Benefit: <metric and target> · Cost: <…> · Risk: <behaviour or API change, memory against CPU, concurrency>
Reversibility: <…> · Confidence: <…>
Spec impact: <the documents, requirements and ADRs that would change>
Verification: <equivalence tests; before/after measurement; how to roll back>   (optimization or refactor only)
Decision: <accepted | rejected | deferred> — by the user, YYYY-MM-DD — <reason>
Implemented through: <FR-/ADR-/CH-> · Revisit when: <…>
```

This is the one proposal format, for every kind of proposal. An optimization's evidence is a
measurement or an estimate at a stated data size, never a hunch. In a spec-driven project the proposal
goes into the register, `docs/discovery/proposals.md`; elsewhere, into the report.
