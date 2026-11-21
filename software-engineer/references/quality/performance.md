# Performance investigation

When something is too slow, its cause is found by measurement, with the same discipline as a bug's
(`debugging.md`). What to change once the cause is known — the algorithm, allocations, data access —
is in `modern-practices.md` "Efficiency principles"; this file is how to find it.

## Contents
- State the problem
- Reproduce it at the right size
- Find where the time goes
- Estimate the gain before the change
- Change one thing, measure again
- Benchmarks that tell the truth
- Keep it from coming back
- What to avoid

## State the problem

- **Slow compared to what.** A number against a target — the NFR, an earlier version, a timing from
  the report. "It feels slow" starts a question; it is not yet a problem. With no target anywhere,
  ask the user for one.
- **Which operation, for whom, at what data size and load, and since when.** If it used to be fast,
  something changed — a release, the data's growth, a configuration, a dependency's version. A
  regression has a starting point: bisect it (`debugging.md` "Narrow it down").
- **Which number counts.** Latency or throughput; the typical case or the tail, at a stated
  percentile. Decide the number that means "fixed" before starting.

## Reproduce it at the right size

- **Production-sized data of the same shape**, the real engine at its production version, realistic
  concurrency, a release build with no debugger attached. Small data hides the quadratic loop; a
  debug build hides everything else. Production data stays where it is (`security.md`): generate data
  of the same size and distribution.
- **Repeat the measurement and report the spread**, after a warm-up. When the noise is larger than the
  difference, there is no result yet.

## Find where the time goes

- **Check for errors first.** Timeouts, retries, exceptions and rejected requests look like slowness;
  a retry storm is not a performance problem.
- **Break the operation's time into its parts** — each call, query and wait, timed at each boundary —
  and follow the largest part down until it cannot be split further.
- **Profile what the time is spent on**: a CPU profiler for computation, an allocation profiler for
  memory pressure, and the waits a CPU profile does not show — locks, I/O, an exhausted connection
  pool, starved threads. For the database, the real query plan and the number of queries per
  operation. The stack playbook names the tools (`modern-practices.md`).
- **For each resource on the path** — CPU, memory, disk, network, pools, threads, locks — check how
  busy it is, whether work is queuing for it, and whether it reports errors. The one with a queue is
  the limiter.
- **A flat profile** — no single hot spot — usually means the cost is structural: work repeated higher
  up the call stack, a layer doing more than the operation needs. Look there before tuning functions.

## Estimate the gain before the change

- **A fix saves at most the share of time its part takes.** Halving a step that takes 10% of the time
  saves 5%. If the best case cannot reach the target, look elsewhere.
- **Check the measurement against a rough calculation** — round trips, queries, bytes and allocations,
  each times its rough cost. A large gap between the two means one of them is wrong.
- **The algorithm first**, then allocations, then avoiding work (`modern-practices.md`).

## Change one thing, measure again

- **One change per measurement**, on the same setup, compared with the baseline. A change that does not
  move the number is reverted, however clever it is.
- **Behaviour stays the same**: the existing tests pass, and a reworked algorithm is compared with the
  old one over generated inputs (`testing.md`, lens 2).
- **Stop at the target.** Beyond it, each gain costs readability for nobody's benefit
  (`modern-practices.md` "Readability still wins").
- **An optimization outside the approved scope is a proposal**, with its measurement as the evidence
  (`review.md` "Improvements are proposals").

## Benchmarks that tell the truth

- **Release build, no debugger, warmed up, nothing heavy running beside it**, repeated with the spread
  reported. The stack's benchmarking tool handles most of this; use it rather than a stopwatch loop.
- **Use the result**, so the compiler cannot remove the work being measured.
- **Watch what it measures while it runs.** Confirm the limiter is the code under test — not the
  benchmark itself, a single thread, or the machine's disk or network.
- **A micro-benchmark shows a function got faster, not the operation.** Confirm the gain on the
  end-to-end measurement.
- **Record with the result** the environment, the versions and the data size.

## Keep it from coming back

- **Where the target matters, the measurement becomes a check that runs regularly** — a load test or
  benchmark with a threshold that fails (`testing.md`, lens 3).
- **A non-obvious optimization keeps its measurement beside it** (`modern-practices.md` "Readability
  still wins"), and goes in the area record when it looks like something to tidy away
  (`decision-records.md` "Code that looks wrong and is not").

## What to avoid

- **Guessing**: changing what looks slow without measuring. The slow part is rarely where it looks.
- **Random tuning**: changing settings one after another and keeping whatever measured better, without
  knowing why.
- **Looking only where your tools shine**: the cause may be in the waits, the database or the network
  rather than the code you can profile.
- **Blaming another component** without a measurement that shows it.
- **Caching over a slow path** before knowing why it is slow (`caching.md` "Decide before caching").
