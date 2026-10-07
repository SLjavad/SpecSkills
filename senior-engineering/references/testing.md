# Testing

A test exists to fail when the behaviour it guards breaks. Tests written to pass — mirroring the
implementation, asserting nothing that matters, covering only the happy path — are worse than none:
they fail for the wrong reasons, get muted, and then everything around them is assumed covered.

## Contents
- Choosing the verification method
- Four lenses on every significant flow
- Beyond the lenses: the flow's own risks
- Integration tests run every external dependency for real
- Writing a test worth having
- Proving the tests can fail
- Sizing the coverage
- Tools

## Choosing the verification method

The one list of verification methods, for code and for requirements alike — strongest first. Use the
strongest that can run, and state which you used. Reading the code and agreeing with it is never
verification.

| Method | For | Record |
|---|---|---|
| Unit test | pure logic — rules, arithmetic, parsing, mapping, state transitions; fast, no I/O, no clock | the test |
| Integration test with Testcontainers | anything that crosses an external dependency: the real engine, the vendor's emulator, or a containerized mock server | the test |
| Characterization | a behaviour-preserving change: capture the current output, change, re-run, **diff** | the diff |
| Evaluation | an output judged over many cases — ranking, classification, extraction, generated text: a versioned dataset, a scoring method and a threshold, run like a test | the score, the dataset and model versions; below the threshold fails |
| Benchmark, load test or probe | a number — latency, throughput, allocations, a query plan — or behaviour where there is no suite to add to | the result, and what it ran against |
| Exercise | calling the running system by hand | the request and the response |
| Structural check | where nothing above reaches the outcome: confirm the mechanism exists — the index, the timeout, the bound | that the mechanism was checked and the outcome was not — never as a measurement |
| Dedicated plan | a requirement important enough that nothing above is honest enough: real load profile, soak, failover drill, penetration test | its report |
| Not verified | nothing above was possible | why, and what would be needed — said out loud, never a blank |

A **probe** — a throwaway script or project that drives the real path and reports what happened —
verifies behaviour as readily as it measures performance. For a functional requirement it drives the
flow end to end against the real database, provider and bus and checks each acceptance criterion; for
a non-functional one it produces the number. A probe over fabricated data proves less than one over
real data, so say what it ran against. Record its output and keep the probe out of the deliverable
tree. A probe verifies once; only a test verifies next month, so prefer the permanent form wherever
the project has a place to put it — and in a project with no suite yet, say what that leaves
unprotected.

## Four lenses on every significant flow

For each flow that matters — money, stored data, permissions, anything a user relies on — look at it
through each lens, ask what would break it, and write the tests that try. Skipping a lens for a flow is
a decision you state, not an omission. The examples under each lens illustrate; they do not bound it.

**1. Business logic and product requirements**
- Each acceptance criterion, including its stated failure behaviour, as a scenario test.
- Invariants and state transitions: the allowed ones, the forbidden ones, and the boundaries between.
- Role rules, money, time and rounding — with the spec's worked examples as literal test data.
- *Example:* cumulative partial refunds never exceed the captured amount — a property test over
  random refund sequences, plus one API test against the real database.
- *UI:* user-flow tests that find elements by role and label, the way a user does.

**2. Technical solution and implementation**
- Correctness against an oracle: the optimised algorithm agrees with a slow reference implementation
  over generated inputs; serialization round-trips; metamorphic relations.
- The paths that are not the main one: errors, retries, timeouts, faults injected at the boundary.
- *Example:* the pricing engine matches a naive reference over 10,000 generated carts.
- *UI:* state logic and formatters (reducers and hooks, in React) tested as plain functions.

**3. Performance**
- The NFR targets as test thresholds: latency and throughput under the stated load, measured, not
  assumed.
- Behaviour at the stated scale: the algorithm stays within its complexity at 10× volume; result sets
  stay bounded; memory, connections and threads stay within their limits.
- Query counts asserted (no N+1), allocation budgets on hot paths, micro-benchmarks for measured hot
  code.
- *UI:* render and bundle-size budgets, interaction latency.

**4. Security**
- The authorization matrix — role × ownership × operation, per endpoint — including another user's or
  tenant's object id (returns no data) and mass assignment (`"isAdmin": true` in a payload is ignored).
- Response over-exposure: fields the caller must not see are absent, not merely hidden by the UI.
- Injection against the real engine; size, depth and rate limits; secrets absent from logs and
  responses.
- Security tests use the real token validation or a test authentication handler — never a weakened
  production setting.
- *UI:* XSS sinks, the content-security policy, and where tokens are stored.

## Beyond the lenses: the flow's own risks

The four lenses are the minimum, not the map. Every flow also depends on properties the lenses do not
name; derive them from its requirements, NFRs, architecture, threat model and failure matrix, and test
the ones that carry real risk. What that list holds depends on the system. Subjects that often matter —
examples, not a checklist:

- **Concurrency** — lost updates and races. *Example:* release 50 bookings for the last seat at once
  through a barrier against the real database, repeatedly: exactly one success, 49 conflicts, inventory
  never below zero.
- **Idempotency and duplicates** — the same request or idempotency key sent sequentially and
  concurrently; the same message delivered twice; a crash between the side effect and the
  acknowledgement.
- **Resilience** — timeouts, retries, partial failure, a dependency that is slow or down, recovery.
- **Data integrity and consistency** — transaction boundaries, constraints, eventual consistency
  between parts that update separately.
- **Compatibility** — schema migrations up and down, contract and API versioning, old clients.
- **Time** — time zones, daylight-saving changes, calendars, ordering by timestamp.
- **Configuration** — defaults, missing or invalid settings, feature flags in each state.
- **Operability** — the logs, metrics and traces an operator needs are actually emitted; startup,
  shutdown and degradation behave as specified.
- **Localization and accessibility** — for anything a person reads or operates.

Name, in the plan step, which subjects a flow needs and why; a subject the system has and no
test covers is a gap to state.

## Integration tests run every external dependency for real

Every integration test that crosses an external dependency runs it with **Testcontainers** — whatever
the dependency is: a database, message broker, cache, search engine, object store, identity provider,
mail or SMS gateway, another of your services, a third-party API. Those are examples; the rule covers
every tool or service outside the process. Testcontainers exists for most major languages; for a stack
it does not cover, use the closest tool that runs the dependency in a throwaway container.

- **Choose the most real option that can run**: the production engine itself; otherwise the vendor's
  official emulator; otherwise a containerized mock server for an API you cannot run — plus a contract
  test wherever the provider's shape can drift independently of your release.
- **Never substitute a different engine** — an in-memory database, SQLite standing in for another
  database, an embedded fake broker — and never mock a dependency you can run. A substitute behaves
  differently exactly where bugs hide: transactions, locking, collation, serialization, error codes.
- **Pin each image to the production version**, from one place in the repository, by tag and ideally
  by digest.
- **Start containers once per test run or per worker**, not per test, unless isolation demands it.
- **Connect through the mapped host and port**, never a fixed one. Wait for readiness — health check,
  port, or log line — with a timeout; never sleep.
- **Keep the resource reaper on** so crashed runs do not leak containers. Container reuse is for local
  development only.
- **One documented reset strategy per suite.** Rolling back a transaction per test isolates only code
  that shares the test's connection and never manages its own transactions; otherwise truncate or
  snapshot-restore between tests. Parallel tests get unique tenants or ids, or a dependency instance per
  worker. Reset every stateful dependency — data, caches, queues, mailboxes.
- **Shared fixtures are thread-safe**, or the tests that share them are serialized explicitly.
- **CI runs them on runners that can run the containers** (typically Linux runners with Docker),
  caches the images, and captures container logs on failure. If CI or your own environment cannot run
  containers, say so and report those tests as written but not run — never substitute another engine,
  and never let the suite be skipped quietly.

## Writing a test worth having

- **Test the rule, not the implementation.** If tidying the code breaks the test, the test was reading
  the code rather than the behaviour. Assert what the caller can observe.
- **Name it after the behaviour**, and cite what it guards. `RoundsUpAtTwoDecimals` beats
  `RoundUp_Test` — the name is the whole message when it fails at 2am in CI — and a requirement or
  flow id in the name or a trait lets the matrix find it.
- **One reason to fail per test.** If it can fail for two unrelated causes, the failure no longer tells
  you which.
- **No logic in the test.** An `if` or a loop computing the expected value re-implements the thing
  under test, so both can be wrong the same way. Write the expected value literally, and write two
  tests instead of one branch.
- **Deterministic or it is noise.** No wall clock, no unseeded random, no dependence on execution
  order, no state shared between tests. Unit tests do no I/O at all; integration tests reach only
  their own containers. Inject the clock instead of reading it.
- **Build the input in the test.** A shared mega-fixture hides which field actually mattered; the
  reader has to see the input that produces the expectation.
- **Mock only what you cannot run.** Over-mocking asserts that the code calls the methods you wrote it
  to call — true by construction, and it locks the design in place.
- **Worked examples are the best test data you will get** — real numbers someone already reasoned
  through, from the spec, an area record or ADR, or the ticket.
- **Cover the boundary and the negative case**, not three variations of the happy path. Empty, zero,
  one, absent, maximum, tie, wrong type.

## Proving the tests can fail

- **See it fail first.** A test that has never been red is not known to work. Break the expectation
  once, watch it fail, then correct it.
- **Mutation testing on the core.** For the domain core — rules, calculations, state transitions — run
  mutation testing: the tool injects small faults and checks that some test fails. Each surviving
  mutant is a missing assertion or dead code; review them. Run it on demand, nightly, or incrementally
  on changed files — not on every build — with a break threshold that only ratchets up. Coverage says
  a line ran; the mutation score says a test would notice if it were wrong.
- **Property-based tests for invariants**, with the seed logged so a failure reproduces.
- **A flaky test is a defect.** Quarantine it with a tracked issue and fix the cause; never retry until
  green.
- **Never delete or weaken a test to make a change pass.** If an expectation must change, the change
  and the requirement that moved are named in the report.

## Sizing the coverage

- **Size the coverage to the consequence, not to how easy the test is to write.** The cheapest tests to
  write are usually the ones least worth having. A flow that moves money or data deserves step-by-step
  coverage through every lens and every risk it carries; changing a default, a key, a literal or a
  field's presence deserves none. Ask what breaks in production if this is wrong — if the answer is
  "someone notices immediately and fixes it", that is not a test, that is a changed line.
- **A "so it never drifts again" guard is still a test, and most are not worth it.** The genre is
  seductive because it feels like diligence rather than testing, so it escapes the judgement applied to
  everything above. It earns its place only when the drift would be **silent** *and* the consequence
  severe — a guarantee that breaks with no error, a message dropped with no log line, money moved with no
  record. When the drift would announce itself, or the fallback is simply correct, the guard is noise
  that makes the suite slower and less trusted.
- **Delete a test that asserts nothing**, and do not add one for a trivial accessor, framework
  behaviour, a third-party library, or configuration wiring. A suite too slow or too brittle to be run
  is worse than a smaller one people trust.
- **Shape**: services lean on integration tests for the data paths, unit tests for dense logic, and a
  few end-to-end tests for the critical journeys. Optimise for tests that are fast, reliable, and fail
  for a meaningful reason.

## Tools

- **The project's test framework**, chosen in its stack ADR, with other libraries alongside where they
  help: Testcontainers modules, assertion, mocking, property-based, mutation and benchmarking tools.
- The project's stack playbook names the maintained tool for each kind, for every stack. Examples of
  the kinds, not a closed list: mutation (Stryker, PIT), property-based (FsCheck, jqwik, fast-check,
  Hypothesis), architecture tests (ArchUnitNET, ArchUnit, dependency-cruiser), load (k6, Gatling,
  Locust), micro-benchmarks (BenchmarkDotNet, JMH, Go's benchmarks). Check maintenance and licence
  before adopting any of them.
