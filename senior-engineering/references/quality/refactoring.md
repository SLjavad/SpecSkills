# Changing existing code safely

Refactoring changes the structure of code without changing what it does, in small steps that each
leave the system working. A restructuring that leaves it broken for days, or changes behaviour on the
way, is a rewrite under another name — and carries a rewrite's risk.

## Contents
- When to refactor
- Pin the behaviour first
- Small steps
- Structure and behaviour apart
- Getting untested code under test
- Replacing something large
- What to avoid

## When to refactor

- **To make the change in hand easy**: reshape the code first, then make the change, which is now
  small. Structure the approved change needs is part of the work — its own steps, done first, and
  named in the report.
- **Anything else is a proposal** — code you passed through, a shape you would prefer, a module in an
  older style (`review.md` "Improvements are proposals").
- **Before changing code that looks wrong, look for its reason** (`decision-records.md` "Code that
  looks wrong and is not").
- **Leave it alone** when it works, rarely changes and nobody needs to understand it, or when it is
  about to be replaced.

## Pin the behaviour first

- **Know what must not change, and how you will see that it did not.** Run the tests that cover the
  code before touching it; they must pass first, so a later failure is yours.
- **Where it has no tests, add characterization tests**: record what it does today, including what
  looks wrong — they exist to detect change, not to judge it (`testing.md`, the method table). A bug
  found this way is reported, not fixed inside the refactoring.
- **Pin what callers observe** — results, stored state, messages, errors — not how the code is built
  (`testing.md` "Writing a test worth having"). Tests that read the implementation break on every
  step and protect nothing.

## Small steps

- **One named transformation per step** — rename, extract, inline, move, split — and the tests run
  after each. A step that fails is undone, not debugged forward.
- **Use the automated refactorings** of the editor or language tooling where they exist; they do the
  same thing every time and miss no reference.
- **Commit after each green step**, so any one step can be undone alone.
- **The system works and can be released after every step.** If it cannot, the steps are too big.
- **Contracts stay stable while callers move**: add the new form, keep the old one delegating to it,
  move the callers, then remove the old one.

## Structure and behaviour apart

- **A step changes structure or behaviour, never both.** The structural change goes first, in its own
  commit or pull request, and the behaviour change follows. Each can then be reviewed on its own
  terms, and the structure can be undone without losing the feature.
- **When a structural need appears in the middle of a behaviour change**, finish or set aside the
  behaviour change, make the structural one separately, then continue.
- **A behaviour difference found during a refactoring is named**, even when it fixes a bug
  (`SKILL.md` "Behaviour never changes silently").

## Getting untested code under test

Code without tests often cannot be tested as it stands: it opens its own connections, reads the clock,
calls a global.

- **Look for a seam** — a place where a dependency can be replaced without editing the code that uses
  it: a constructor parameter, an interface it already takes, a function passed in.
- **Where there is none, make the smallest mechanical change that creates one** — pass the dependency
  in instead of creating it inside — and nothing more until the tests exist.
- **Test from outside when a seam would need a large change.** An integration test against the real
  dependencies (`testing.md`) needs no seam and pins behaviour from where callers see it.
- **New logic goes into new code.** Write it as a separate unit with its own tests and call it from the
  old code, or wrap the old function in a new one that adds the behaviour before or after it. The old
  code gets no worse while it waits.
- **To understand tangled code, refactor a scratch copy freely, learn, and throw it away**; then make
  the real change in steps, with tests.

## Replacing something large

- **No big-bang rewrite.** It chases parity with a system that keeps changing, and nothing ships until
  the end.
- **Replace gradually.** For a component, put an abstraction in front of it, move the callers to the
  abstraction, build the new implementation behind it, and switch over — releasable throughout. For a
  whole system, route one capability at a time to the new one until the old has nothing left to do.
- **Where results must match, run old and new side by side** and compare their outputs before
  switching; then remove the old one and every transitional piece.
- **A large replacement is an architecture decision**: an ADR, decided by the user
  (`decision-records.md`).

## What to avoid

- **Refactoring and changing behaviour in one step.**
- **Refactoring with no tests running.** "It compiles" proves the syntax, not the behaviour.
- **A long-lived branch** that drifts from the main line for weeks while the refactoring grows.
- **Editing behaviour tests to make a refactoring pass.** A refactoring does not change behaviour; a
  test that must change was testing the implementation.
- **Tidying code the change does not need**, folded into the change instead of proposed.
