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

Judge the code by the fixed set of principles in `SKILL.md` — the project's declared rules first —
using the signals in `design.md`: SOLID, "Balance" and the entry-point test. Raise a finding only with a
concrete change scenario or defect risk; "violates principle X" on its own is not a finding.
**Over-engineering is a finding with the same weight as a violation.** Layering and module boundaries
are the project's chosen architecture, checked by its architecture tests and the dependency lens below.

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
realistic size the spec states. Check the code against `modern-practices.md` ("Efficiency principles")
and the stack playbook, and look too for what they do not list:

- complexity at realistic N — nested scans, lookups or sorts inside loops; small N rarely matters;
- cartesian explosions, and missing indexes for the queries actually issued;
- lazy sequences enumerated twice; lock contention on common paths;
- serializer or option objects rebuilt per call; expensive log arguments evaluated when the level is
  off; exceptions used for control flow on hot paths;
- regular expressions on untrusted input with a backtracking engine and no timeout.

## Lens: security, tests, readability

- **Security** — the audit checklist in `security.md`, in every review, not only when asked.
- **Tests** — `testing.md`: the four lenses covered for significant flows, and the flow's other risks —
  concurrency, idempotency, resilience and whatever else it carries; tests that cannot fail, mirror the
  implementation, or were weakened; mutation score on the core; Testcontainers wherever an external
  dependency is touched.
- **Readability and leftovers** — misleading names, clever lines, debug output, commented-out code,
  stray `TODO`s, scaffolding, dead abstractions.

## Writing findings

The one finding format, for every review — in a report, or in a spec-driven review file:

```markdown
### F-NN — <short title>
Severity: blocker | major | minor | note · Blocking: yes | no · Introduced by this change: yes | no
Lens: <the lens that found it, or other: <name>> · Against: <AC, FR/NFR or ADR id, where it is against one>
Location: <path>:<line>  (or the spec file and id, for a spec defect) · Status: open | fixed | rejected | deferred

**What.** The defect, in one or two sentences.
**Why it matters.** The input, state or sequence that produces a wrong result, or the specific thing a
reader will misunderstand. If you cannot name one, it is a note.
**Evidence.** What you ran or read that shows it: the test, the request and response, the measurement.
**Suggested fix.** The smallest change, not a rewrite of the area.
**Outcome.** Filled in by whoever acts on it: what was done, or the written reason for rejecting it.
```

- **A security finding** also records the exploit input, the impact, the regression test that proves
  the fix, its OWASP Top 10 or ASVS category and CWE, and a `Rating:` — a CVSS vector for a concrete
  vulnerability rated high or critical, likelihood × impact otherwise. Critical and high are always
  `blocker`, and block release.
- **Severity means something.** A blocker produces wrong data, loses money, breaks a contract, or opens
  a security hole. A major is a real defect on a reachable path. A minor is a defect on an unlikely path
  or a genuine readability problem. A note has no defect behind it — keep notes few, or they train the
  reader to skim. A blocker or major is always blocking.
- **Do not manufacture findings.** A reviewer told to find problems finds some, and fixing invented ones
  breeds over-engineering. A clean review is a valid outcome — say exactly what you checked.

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
