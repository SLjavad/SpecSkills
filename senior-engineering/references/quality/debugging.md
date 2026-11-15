# Debugging

A bug is fixed when its cause is known, the cause is removed, and a test shows it. A change that makes
the symptom go away without an explanation is a guess, and a guess that seems to work hides the defect
until it returns somewhere worse.

## Contents
- When this applies
- Stabilize first
- Reproduce
- Narrow it down
- One hypothesis at a time
- Fix the cause
- Prove it and guard it
- When it will not reproduce
- When fixes keep failing
- Record what you learned

## When this applies

Any failure: wrong output, a crash, a failing or flaky test, a broken build, an integration that
stopped working. Something too slow follows `performance.md`, which measures where this file
reproduces. It applies most when the cause looks obvious or time is short —
that is when guessing is most tempting and costs most. An obvious-looking cause is checked like any
other.

## Stabilize first

When a live system is failing, restoring service comes before finding the cause: roll back, turn the
feature flag off, shed load. Propose the step and let the user decide; never act on a live system on
your own. Before anything rotates away, save the evidence — the logs, the stored record, the dump, the
exact request. Production data stays where it is; take only what is safe to move
(`security.md` "Keeping confidential data off external tools").

## Reproduce

- **Read the whole error first** — every line of the message and the stack trace, the inner error, the
  log lines before it. The answer is often already there.
- **Make it fail on demand**: the steps, the input, the data and the environment that produce it every
  time. Reproduce where the real dependency runs — the same engine, versions and configuration
  (`testing.md` "Integration tests run every external dependency for real").
- **Shrink the reproduction.** Remove half the input, the steps or the data, and keep the half that
  still fails; repeat until nothing more can go. A minimal case often names the cause by itself, and
  shows when two reports share one.
- **Write it as a script or a test** so every experiment after this runs the same check.

A failure that will not reproduce has its own section below.

## Narrow it down

- **Check the plug.** Is the code running the code you changed — built, deployed, with the configuration
  and the database you think? Many hunts end here.
- **Look; do not reason about what the code should do.** Observe the actual values at each boundary —
  logs, a debugger, the stored data, the message on the bus — and find the first place a value is
  wrong. The cause is at or before that place, rarely where the crash surfaced.
- **Trace the bad value back to where it was made**, not to where it was used.
- **Ask what changed**: a release, a configuration, a dependency's version, the data, the load. If a
  version that worked is known, bisect the history with the reproduction script
  (`git bisect run`, or the version-control system's equivalent); it finds the change mechanically.
- **Compare with a case that works** — the same flow with another input, user or environment — and
  list every difference between the two.
- **Temporary instrumentation lives in a probe or a scratch copy** (`testing.md`), never in the
  deliverable. A log line the operator would need next time is not temporary: keep it, properly.

## One hypothesis at a time

- **State the hypothesis and what it predicts**, so the experiment can refute it: "if the cache key
  drops the tenant, a second tenant's request returns the first tenant's data."
- **Test it with the smallest experiment**, and change one thing at a time. Undo an experiment that
  did not help before the next one, or two changes end up tangled.
- **Try the likeliest and cheapest explanation first.** Correlation is not cause: a metric that moved
  with the failure may share a cause with it, or nothing at all.
- **Keep a log** — each hypothesis, the experiment, the result, negative results included. It stops
  the same dead end being walked twice, and lets someone else, or a later session, carry on.
- **"I do not understand this yet" is an honest state.** Say it, rather than presenting a guess as a
  finding.

## Fix the cause

- **Fix only when the diagnosis explains both how the failure arises and why the code is wrong.** If
  it explains one and not the other, keep narrowing.
- **Fix it where the cause is**, in the shared code, not where it surfaced. A special case for the
  failing input, a swallowed error, or a retry, sleep or longer timeout added without a diagnosis that
  calls for it, hides the defect.
- **Search for the same cause elsewhere** — the same pattern, the same misuse, the same wrong
  assumption — and fix or report each instance.
- **Before changing code that looks wrong, look for its reason** (`decision-records.md` "Code that
  looks wrong and is not"). The odd line may be an earlier fix.
- **One fix per cause.** A refactoring, a tidy-up or a second improvement noticed on the way is a
  proposal, reported separately.

## Prove it and guard it

- **The reproduction becomes a regression test**, at the lowest level that can show the failure
  (`testing.md`) — an integration test when the cause lay in a dependency's real behaviour.
- **It fails without the fix and passes with it.** Whatever order you wrote them in, check both: undo
  the fix once and watch the test fail. A test that passes either way guards nothing.
- **Run the suites the fix touches**, so it is known to break nothing else.
- **A failure that stopped on its own is not fixed.** If it vanished without an explanation, it will
  come back; report it as unresolved.

## When it will not reproduce

Intermittent failures usually come from concurrency, time, ordering, state shared between tests or
requests, resource exhaustion, or a difference between environments.

- **Make it more likely**: run it many times, in parallel, under load, with the random seed and the
  timing logged. Vary one environment factor at a time — version, configuration, data, machine.
- **Add the diagnostics that would catch it next time** — the identifiers, the state and the timing
  at the point of failure — as permanent log lines, if the operator would need them too.
- **A flaky test is a defect** (`testing.md`); a retry until green is not a fix.
- **If investigation shows the cause is truly outside the code**, record what was found, add the
  handling and diagnostics it calls for, and report it with what is still unknown.

## When fixes keep failing

A fix that did not hold means the diagnosis was wrong. Go back to the reproduction rather than trying
the next idea. **After three fixes that did not hold, stop**: report to the user what is known, what
was tried and what each attempt showed. Repeated failure usually means the problem is in the design,
not the line being patched, and that is the user's decision. Explaining the problem from the start —
to the user, or in writing — often shows the assumption that was wrong.

## Record what you learned

- **Report** the cause, the evidence for it, the fix and the test that guards it.
- **When the cause was not obvious**, or the fix looks odd, write it in the area record with the failure
  it prevents (`decision-records.md`). That entry stops the next reader undoing it.
- **When the bug came from a gap in the spec**, say so: it is a question for the user, and the spec is
  amended with the answer.
