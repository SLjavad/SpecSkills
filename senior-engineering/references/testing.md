# Testing

A test exists to fail when the behaviour it guards breaks. Tests written to pass — mirroring the
implementation, asserting nothing that matters, covering only the happy path — are worse than none:
they fail for the wrong reasons, get muted, and then everything around them is assumed covered.

## Contents
- Choosing the verification method
- Challenge every significant flow from four lenses
- Integration tests run against real infrastructure
- Writing a test worth having
- Proving the tests can fail
- Sizing the coverage
- Tools

## Choosing the verification method

Match the method to what is being verified, and state which you used.

| What is being verified | Method |
|---|---|
| Pure logic — rules, arithmetic, parsing, mapping, state transitions | Unit test: fast, no I/O, no clock |
| Anything touching infrastructure you own or run — database, queue, cache, search, object store | Integration test on Testcontainers, against the real engine |
| A third-party service you cannot run | A stub at the HTTP boundary, plus a contract test where the provider's shape can drift |
| A behaviour-preserving change | Characterization: capture the current output, change, re-run, **diff** |
| A number — latency, throughput, allocations, a query plan — or a one-off exploration | A benchmark, load test or throwaway probe; record the result and what it ran against |
| A project with no test suite yet | A probe now — and say plainly what that leaves unprotected next month |

A **probe** — a throwaway script or project that drives the real path and reports what happened —
verifies behaviour as readily as it measures performance: that the row is written, the message
published, the response shaped as documented, the query plan what you expected. Record its output;
throw the probe away. A probe verifies once; only a test verifies next month, so prefer the permanent
form wherever the project has a place to put it. Reading the code and agreeing with it is not
verification.

## Challenge every significant flow from four lenses

For each flow that matters — money, stored data, permissions, anything a user relies on — ask what
each lens would try to break, and write the tests that try it. Not every flow needs every lens;
skipping one is a decision you state, not an omission.

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
- Error, retry and timeout paths; migrations; faults injected at the network boundary.
- *Example:* the pricing engine matches a naive reference over 10,000 generated carts.
- *UI:* state logic and formatters (reducers and hooks, in React) tested as plain functions.

**3. Performance, concurrency and idempotency**
- Lost updates and overbooking: release N writers at once through a barrier against the real
  database, and repeat the run. *Example:* 50 concurrent bookings for the last seat yield exactly one
  success, 49 conflicts, and inventory never below zero.
- Duplicates: the same idempotency key sent sequentially and concurrently; the same message delivered
  twice; a crash between the side effect and the acknowledgement.
- Starvation and blocking: run with a capped thread pool or event loop; use the race detector where
  the stack has one.
- Query counts asserted (no N+1), allocation budgets on hot paths, and load tests whose thresholds are
  the NFR targets.
- *UI:* out-of-order responses, double submit, render and bundle-size budgets.

**4. Security**
- The authorization matrix — role × ownership × operation, per endpoint — including another user's or
  tenant's object id (returns no data) and mass assignment (`"isAdmin": true` in a payload is ignored).
- Response over-exposure: fields the caller must not see are absent, not merely hidden by the UI.
- Injection against the real database; size, depth and rate limits; secrets absent from logs and
  responses.
- Security tests use the real token validation or a test authentication handler — never a weakened
  production setting.
- *UI:* XSS sinks, the content-security policy, and where tokens are stored.

## Integration tests run against real infrastructure

Integration tests that touch a database, message broker, distributed cache, search engine or object
store use **Testcontainers**, which exists for most major languages — for a stack it does not cover,
the closest tool that runs the real engine in a throwaway container. The point is to test against the
engine production runs: a substitute behaves differently exactly where bugs hide — transactions,
locking, collation, JSON handling, constraint errors.

- **Never substitute another engine** — an in-memory database, SQLite standing in for a different
  database, an embedded fake broker — and never mock infrastructure you own.
- **Pin each image to the production version**, from one place in the repository, by tag and ideally
  by digest.
- **Start containers once per test run or per worker**, not per test, unless isolation demands it.
- **Connect through the mapped host and port**, never a fixed one. Wait for readiness — health check,
  port, or log line — with a timeout; never sleep.
- **Keep the resource reaper on** so crashed runs do not leak containers. Container reuse is for local
  development only.
- **One documented reset strategy per suite.** Rolling back a transaction per test isolates only code
  that shares the test's connection and never manages its own transactions; otherwise truncate or
  snapshot-restore between tests. Parallel tests get unique tenants or ids, or a database per worker.
  Flush caches and purge queues as well.
- **Shared fixtures are thread-safe**, or the tests that share them are serialized explicitly.
- **CI runs them on runners that can run the containers** (typically Linux runners with Docker),
  caches the images, and captures container logs on failure. If CI cannot run containers, say so — never let the suite be skipped quietly.

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
- **Mock only at boundaries you do not own.** Over-mocking asserts that the code calls the methods you
  wrote it to call — true by construction, and it locks the design in place.
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
  coverage from every relevant lens; changing a default, a key, a literal or a field's presence
  deserves none. Ask what breaks in production if this is wrong — if the answer is "someone notices
  immediately and fixes it", that is not a test, that is a changed line.
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

The project's stack playbook names the maintained tool for each kind — for example Stryker (.NET,
JavaScript/TypeScript) or PIT (JVM) for mutation; FsCheck, jqwik, fast-check or Hypothesis for
properties; ArchUnitNET, ArchUnit or dependency-cruiser for architecture tests; k6, Gatling or Locust
for load; BenchmarkDotNet, JMH or Go's benchmarks for micro-benchmarks. Check maintenance and licence
before adopting one — test libraries change licence too.
