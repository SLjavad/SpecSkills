# Phase 0 — Setup

**Goal:** before any spec is written, the project knows how it will be worked on, and has the skeleton
every later document plugs into.

## Contents
- Ask the operating mode
- Decide the size and the architecture, with the user
- AGENTS.md and CLAUDE.md
- The docs skeleton
- The indexes
- Existing projects
- Then stop

## Ask the operating mode

Ask once, early, with real options:

- **Single agent** — one agent writes the specs, implements, and reviews; the usual choice for a small
  project. Prefer a fresh-context session for the review; a reviewer with no memory of writing the code
  catches more.
- **Lead and coder** — a lead agent (product manager, tech lead, architect, reviewer) writes specs,
  ADRs, plans and task briefs, and reviews; a coder agent implements and reports. They communicate
  only through files, and the user can step in at any point. Ask which tool each agent runs in, and on
  whose machine: everything the agents share must be written into the project, because these skills
  live in one user's skills folder, not in the project.
- **Another split the user prefers** — a separate reviewer, several coders. Map it onto the same roles
  and files.

Record the answer under "Working mode" in `AGENTS.md`. In multi-agent mode, read `multi-agent.md` and,
before phase 1, set up `docs/handoff/` from `handoff-templates.md` — protocol, control (paused), board
and templates — and, when any agent works without these skills installed,
`docs/engineering/principles.md` (senior-engineering `project-knowledge.md`).

## Decide the size and the architecture, with the user

Every later phase depends on how heavy this project should be, so it is decided once, here — never
re-guessed by each session. The inputs come from discovery's technical sweep (`discovery.md`): expected
scale and growth, lifespan, the existing systems it must run alongside, where it will be deployed,
whether any part must scale or deploy separately, and the obligations the product sweep found. Propose, with your
reasons; the user decides.

- **Size — small or standard.** Propose small when all of these hold; otherwise standard:
  - one deployable, and no stated need to scale or deploy any part separately;
  - about five capabilities or fewer — the distinct things users can do, counted from discovery's
    product sweep;
  - no regulatory, contractual or audit obligation that needs a formal record of decisions and
    traceability;
  - no stated growth that would break the points above within the expected lifespan.

  Size is a property of the software, never of the people building it. Where the user has
  already stated the size, use it and record it as `answered`. Where a point is open, ask it in the first
  batch of questions. On the border, propose small and record it as `assumed` — growing out of it is
  cheap by design (`small-track.md`), shrinking from standard is not. Size is not stakes either: a small
  tool that moves money still gets full tests on its money rules and a security review.
- **The architecture shape — the lightest one the stated scale needs.** A monolith is the usual start.
  A modular monolith — one deployable whose modules own their data and talk through explicit
  interfaces — where the domain has clear boundaries and a later split is plausible: it keeps that split
  open without paying for it now. Separate services only for a stated need — independent scaling
  or deployment.
- **The internal style**: plain layers or vertical slices, or clean or hexagonal where the business
  rules are complex and long-lived.
- **The practices this project uses**, recommended from its size: how far the spec phases merge their
  files, short or full ADRs, when a change gets its own folder, and where mutation, architecture and
  load tests apply. A small project usually takes the **small track** (`small-track.md`): three spec
  files, one change file per change, short ADRs, and two approval stops instead of five.

Record the size, shape and style as one decision in the first ADR (senior-engineering
`decision-records.md`) — `proposed`, citing the discovery answers and any open or `assumed` entries it
rests on — and, under "Working mode" in `AGENTS.md`, the size and architecture with the ADR's link, and
the practices. The user decides it at gate 0 or, where it rests on open questions, once they are
answered and before the tech spec starts.

The tech spec details this architecture and checks it against the requirements; changing it later —
growing from small to standard included — is a superseding ADR with the user's yes. A change of size
applies forward: merged files split when next touched or at the cap, accepted ADRs stay as written,
and new practices start with the next change.

No size changes senior-engineering's non-negotiables and standing defaults, the data-egress rules,
Testcontainers for real dependencies, or tests on every rule that was hard to get right.

## AGENTS.md and CLAUDE.md

Create or update both from the templates in senior-engineering's `references/project-knowledge.md`.

- **An existing `AGENTS.md`** is updated, not replaced; show the user the diff.
- **Instruction files for other tools** (`.cursorrules`, Copilot instructions and the like): fold their
  content into `AGENTS.md`, and leave each as a short shim pointing to it.
- **`CLAUDE.md` holds `@AGENTS.md`** plus Claude-only notes, and nothing else is imported — imports
  load at startup, and the specs must load only on demand.
- **Add each line of `AGENTS.md` when its target exists.** A link to a file nobody has written yet, or a
  `Commands` section before the skeleton step has created the commands, is a placeholder — leave it out
  until it is true.

## The docs skeleton

```
docs/
  specs/                  living specs: the system as it is (or, before release 1, as it is being built)
    README.md             manifest: every spec file, one line each
    glossary.md           every domain term, defined once
    01-product/  02-requirements/  03-tech/
  changes/                work in flight: one folder per change, then archive/
    README.md
  adr/                    decisions
    README.md
  discovery/
    understanding.md      the confirmed playback of product and technical context
    questions.md          gray-area register (Q-)
    proposals.md          proposal register (P-)
  engineering/            README.md index; stack playbooks, areas/ records, principles
  handoff/                multi-agent only: PROTOCOL.md, CONTROL.md, BOARD.md, templates/
```

Create `AGENTS.md`, `CLAUDE.md`, `docs/specs/README.md`, `docs/discovery/` and `docs/adr/` (for the
architecture ADR) now; create each other folder when its phase starts, never as empty placeholders.
Under the small track the layout is the one in `small-track.md`.

**The initial build is change CH-001.** Its product, requirements and tech spec are written directly
into `docs/specs/` — nothing is built yet, so there is nothing to diverge from — while its plan, task
files and reviews live in `docs/changes/CH-001-initial-build/`. Every later major change writes deltas
instead (`changes.md`).

## The indexes

**`docs/specs/README.md`** — the manifest, under 150 lines:

```markdown
# <Project> — specifications
Status: draft | approved · Updated: YYYY-MM-DD
Summary: The living specification — what the system is, what it must do, how it is built. Start here.

## Reading paths
- New to the project: docs/specs/01-product/overview.md → docs/specs/02-requirements/overview.md →
  docs/specs/03-tech/architecture.md
- Implementing a task: the files your brief or plan step lists — nothing else by default.
- Reviewing: the brief, the requirement files it cites, the tech files for the components it touches.

## Files
| File | Holds | IDs | Status |
|---|---|---|---|
| docs/specs/glossary.md | every domain term, defined once | — | approved |
| docs/specs/01-product/overview.md | summary, problem, value, primary goal | — | approved |
| docs/specs/02-requirements/functional/booking.md | booking capability requirements | FR-010–FR-021 | approved |
```

List every file, one line each, with its path from the repository root. Collections — flows, rules,
aggregates — are listed file by file too, so any living document is two hops from `AGENTS.md`.

**`docs/engineering/README.md`** — the same shape, listing the stack playbooks, the area records under
`areas/`, and `principles.md` when it exists.

**`docs/changes/README.md`**:

```markdown
| Change | Title | Status | Opened | Closed | Folder |
|---|---|---|---|---|---|
| CH-001 | Initial build | in progress | YYYY-MM-DD | — | CH-001-initial-build/ |
```

Statuses: proposed → approved → in progress → in review → merged → archived (or rejected).

**`docs/adr/README.md`**:

```markdown
| ADR | Title | Status | Date | Supersedes / superseded by |
|---|---|---|---|---|
```

## Existing projects

A project with code but no specs does not get a reverse-engineered bundle of everything. Write
`AGENTS.md`, a short product overview and the glossary, and the living specs for the area the first
change touches; the specs grow change by change. Backfill ADRs only for decisions that matter now.

Its architecture is the one that exists: record its size, shape and style as the first ADR instead of
choosing again; changing it is a proposal, like any other. The living specs for the area describe the
system as it is, and the first change writes deltas against them, like any later change.

## Then stop

Continue straight into discovery (`discovery.md`): the sweep, the playback and the first batch of
questions. Then stop at gate 0 — present the mode recorded, the size, architecture and practices
proposed, the files created, the playback, the `assumed` entries and the questions — and wait for the
user's decisions and corrections before writing the product spec. When proposing the small track, draft
through to its first stop instead (`small-track.md`).
