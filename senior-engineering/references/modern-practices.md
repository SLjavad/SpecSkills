# Current, idiomatic, efficient code

Your knowledge of every stack is a snapshot, and the platforms move — major releases every year,
security fixes every month, APIs superseded, libraries re-licensed. Code written from memory is
written for the version you remember. This file is how you close that gap for whatever stack the
project uses; the stack itself is chosen in the tech spec, not here.

## Contents
- Know the versions before writing code
- The stay-current routine
- The stack playbook
- Efficiency principles
- Superseded patterns
- Readability still wins

## Know the versions before writing code

Read the project's toolchain files, not your assumptions: the SDK or runtime pin, the target
framework, the language version, the lock file, the central package file, the container base image.
Then read the project's stack playbook, `docs/engineering/stack-<name>.md`. Flag anything past or near
its end of support.

## The stay-current routine

1. **Before using an API or pattern** you have not verified for this version, check the vendor's
   documentation for that version — the vendor's documentation MCP server first where one is
   configured, the official documentation site otherwise. Confirm the minimum version on the API page.
2. **Before recommending or adding a library**, check its registry page: latest version and date,
   maintenance activity, deprecation, licence (popular libraries have moved to commercial terms),
   supported runtimes, and known vulnerabilities. Adding a dependency is a proposal the user approves.
3. **Before an upgrade**, read the breaking-changes pages for every component that moves.
4. **Keep analyzers and linters at a pinned level** and raise it deliberately; treat their warnings
   about outdated or slow patterns as findings.
5. **When sources disagree**: the documentation outranks your memory on facts; the issue tracker
   outranks the documentation on gaps and bugs. When the documentation and the codebase disagree about
   what the code does, stop and ask — the code may be wrong, the docs may describe another version, or
   the deviation may be deliberate.
6. **Queries stay generic** — see `security.md`, "Keeping confidential data off external tools".
7. **Record what you learned** in the playbook, with the source and the date.

## The stack playbook

One file per stack in the project — for example `docs/engineering/stack-dotnet.md`,
`docs/engineering/stack-react.md` — written when the stack ADR is accepted and refreshed when versions
move. It is the project's current, sourced answer to "how do we write this stack here". Research it
across sources — vendor documentation, release notes and what's-new pages, the platform's performance
write-ups, registries, issue trackers — synthesize, and keep it under 300 lines.

```markdown
# <Stack> playbook
Status: current · Last verified: YYYY-MM-DD · Pinned by: ADR-NNNN
Summary: How <project> writes <stack>: versions, idioms, performance practice, what not to use.

## Versions and support
| Component | Pinned | Support ends | Source |
|---|---|---|---|

## Use
| Rule | Since (version) | Use when | Not when | Source |
|---|---|---|---|---|

## Performance and allocation practice
| Rule | Since | Use when | Not when | Source |
|---|---|---|---|---|

## Concurrency and async
## Data access
## Security-relevant defaults
## Test toolchain
Unit · integration (Testcontainers modules and pinned images) · mutation · property-based ·
architecture tests · load and benchmarks — the maintained tool for each, with licence notes.

## Superseded — do not generate
| Old | Use instead | Since | Source |
|---|---|---|---|

## Analyzers and build gates

## Sources
| Source | What it contributed | Checked |
|---|---|---|

## Refresh when
A pinned version changes · a new major release ships · a review finds an outdated pattern ·
six months have passed since "Last verified".
```

Every rule names the version it needs and when **not** to apply it. A rule without its limits gets
applied everywhere, including where it hurts.

## Efficiency principles

Stack-neutral; the playbook holds the concrete APIs.

- **Measure first.** Benchmarks, profilers, and real query plans on production-like data. An
  optimization without a measurement is a guess with a maintenance cost.
- **In this order**: the algorithm and data structure; then allocations and memory layout; then
  avoiding work — caching, batching, laziness.
- **Choose structures by access pattern.** Read-mostly lookups built once deserve a structure optimized
  for reads, such as frozen or perfect-hash collections where the stack has them.
- **Expose immutable or read-only views** of collections, never the mutable original — clearer
  contracts and fewer defensive copies.
- **Allocation-aware APIs on hot paths**: span- or slice-based APIs, pooled buffers and connections,
  streaming instead of buffering large payloads — in .NET, for example, `Span<T>`, `Memory<T>` and
  `ArrayPool<T>`; elsewhere, the stack's equivalents.
- **Asynchronous all the way**: never block on async work, propagate cancellation, bound concurrency
  and queues.
- **Data access**: no N+1, project only the columns needed, paginate by key, use set-based updates for
  bulk changes, and read the query the ORM actually emits.
- **Compile-time over run-time** where the stack offers it — source-generated serializers, loggers and
  regular expressions over reflection.
- **UI**: derive values during rendering, keep side effects (React effects, for example) for
  synchronizing with the outside world, hold bundles within budget, and measure interaction latency
  with the browser's own tools.

## Superseded patterns

Code from memory drifts toward the idioms that were current when the memory formed. When you produce
a construct you have written many times, check it against the playbook's "Superseded" table and the
analyzer output. The usual shapes: a new HTTP client per call; the wall clock read inside domain
logic; a deprecated resilience or serialization library chosen by habit; a lock or cache API that has
a better successor; a documentation generator the framework now provides natively.

## Readability still wins

Modern idioms that are both clearer and faster — read-only collections in any language; in C#, for
example, collection expressions, pattern matching and records — are the default everywhere. Low-level performance constructs — pooling, stack
allocation, unsafe code, hand-tuned loops — belong only on a measured hot path, encapsulated behind a
readable interface, with the measurement recorded next to them. If a reader must re-read a line to see
why it is correct, the gain had better show in the numbers.
