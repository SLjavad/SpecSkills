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
  ADRs and plans, and reviews; a coder agent implements and reports. They communicate
  only through files, and the user can step in at any point. Ask which tool each agent runs in, and on
  whose machine: everything the agents share must be written into the project, because these skills
  live in one user's skills folder, not in the project.
- **Another split the user prefers** — a separate reviewer, several coders. Map it onto the same roles
  and files.

Record the answer under "Working mode" in `AGENTS.md`. In multi-agent mode, before phase 1, set up
`docs/handoff/` as `multi-agent.md` describes — the protocol and the board.

## Decide the size and the architecture, with the user

Every later phase depends on how heavy this project should be, so it is decided once, here — never
re-guessed by each session. The inputs come from discovery's technical sweep (`discovery.md`): expected
scale and growth, lifespan, the existing systems it must run alongside, where it will be deployed,
whether any part must scale or deploy separately, and the obligations the product sweep found. Propose, with your
reasons; the user decides.

- **Size — small or standard.** Small is a script, a utility or a one-job tool. Propose it when all
  of these hold; otherwise standard:
  - one program that does one job, whose whole description fits one page;
  - run by its owner or a few people, not offered to users as a product;
  - no regulatory, contractual or audit obligation;
  - not expected to grow into a maintained product.

  Size is a property of the software, never of the people building it. Where the user has already
  stated the size, use it. Where a point is open, ask it in the first batch of questions. On the
  border, propose small and say it is an assumption — growing out of it is cheap by design
  (`small-track.md`), shrinking from standard is not. **A small project takes the small track**: one
  page and one approval, and nothing below this point but `AGENTS.md` and `CLAUDE.md`.
- **The architecture shape — the lightest one the stated scale needs**: one deployable, a modular
  monolith, or services. When each fits is in senior-engineering's `references/architecture/` —
  `modular-monolith.md` and `microservices.md`; services only for a stated need.
- **The internal style, per module** — Clean or vertical slices, chosen from each style's "When it
  fits" (`clean.md`, `vertical-slice.md`) and the module's classification (`ddd-strategic.md`
  "Subdomains") — for the modules already known; the tech spec decides the rest.
- **The practices this project uses**: how far the spec phases merge their files, short or full
  ADRs, when a change gets its own folder, and where mutation, architecture and load tests apply —
  the lighter end for a modest application.

Record the size, the shape and the style — per module where the modules are already known — as one
decision in the first ADR, the architecture ADR (senior-engineering `decision-records.md` "The
architecture ADR") — `proposed`, citing the discovery answers and any open or `assumed` entries it
rests on — and, under "Working mode" in `AGENTS.md`, the size and architecture with the ADR's link,
and the practices. The user decides it at gate 0 or, where it rests on open questions, once they are
answered and before the tech spec starts. The tech spec completes its module table as a dated
addendum (`tech-spec-structure.md`, Step 2).

The tech spec details this architecture and checks it against the requirements; changing it later is
a superseding ADR with the user's yes. A change of practices applies forward: merged files split
when next touched or at the cap, accepted ADRs stay as written, and new practices start with the
next change. A small-track tool that grows moves to the standard track (`small-track.md`,
"Outgrowing it").

**Size is not stakes.** Size removes documents and stops, never scrutiny: no size changes
senior-engineering's rules, and a small tool that moves money still gets full tests on its money rules
and a security review.

## AGENTS.md and CLAUDE.md

Create or update both from the templates in senior-engineering's
`references/project/project-knowledge.md`, and write `docs/engineering/principles.md` from the same
file, for any agent without these skills.

- **Ask for the project's own rules** as one question in the first batch — the kinds the template
  lists under "Rules for this project" — and record each there, with its reason. One still unset is
  asked before the first action it would govern. The skills set none of them.

- **An existing `AGENTS.md`** is updated, not replaced.
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
  handoff/                multi-agent only: PROTOCOL.md, BOARD.md
```

Create `AGENTS.md`, `CLAUDE.md`, `docs/specs/README.md`, `docs/discovery/`, `docs/adr/` (for the
architecture ADR) and `docs/engineering/` (its index and `principles.md`) now; create each other folder
when its phase starts, never as empty placeholders.
A small-track project has only `AGENTS.md`, `CLAUDE.md` and its page (`small-track.md`).

**The initial build is change CH-001.** Its product, requirements and tech spec are written directly
into `docs/specs/` — nothing is built yet, so there is nothing to diverge from — while its
`proposal.md`, plan, task files and reviews live in `docs/changes/CH-001-initial-build/`. Every later
major change writes deltas instead (`changes.md`).

## The indexes

**`docs/specs/README.md`** — the manifest, under 150 lines:

```markdown
# <Project> — specifications
Status: draft | approved · Updated: YYYY-MM-DD
Summary: The living specification — what the system is, what it must do, how it is built. Start here.

## Reading paths
- New to the project: docs/specs/01-product/overview.md → docs/specs/02-requirements/overview.md →
  docs/specs/03-tech/architecture.md
- Implementing a task: the files your plan step lists — nothing else by default.
- Reviewing: the plan step, the requirement files it cites, the tech files for the components it touches.

## Files
| File | Holds | IDs |
|---|---|---|
| docs/specs/glossary.md | every domain term, defined once | — |
| docs/specs/01-product/overview.md | summary, problem, value, success, scale | — |
| docs/specs/02-requirements/functional/ordering.md | ordering capability requirements | FR-010–FR-021 |
```

List every file, one line each, with its path from the repository root. Collections — flows, rules,
aggregates — are listed file by file too, so any living document is two hops from `AGENTS.md`.

**`docs/engineering/README.md`** — the same shape, listing the stack playbooks, the area records under
`areas/`, and `principles.md` when it exists.

**`docs/changes/README.md`**:

```markdown
| Change | Title | Folder |
|---|---|---|
| CH-001 | Initial build | CH-001-initial-build/ |
```

**`docs/adr/README.md`**: `| ADR | Title |`, one row each.

Statuses live in each change's `proposal.md` and each ADR's header, never in these indexes.

## Existing projects

A project with code but no specs does not get a reverse-engineered bundle of everything. Write
`AGENTS.md`, a short product overview and the glossary, and the living specs for the area the first
change touches; the specs grow change by change. Backfill ADRs only for decisions that matter now.

Its architecture is the one that exists: record its size, shape and style as the first ADR instead of
choosing again — under the style's usual name, layered for example, even where senior-engineering has
no file for it; changing it is a proposal, like any other. The living specs for the area describe the
system as it is, and the first change writes deltas against them, like any later change.

A requirement the code already meets is marked `existing` in the matrix; one it fails gets a *Known
defect* (`requirements.md`).

## Then stop

Continue straight into discovery (`discovery.md`): the sweep, the playback and the first batch of
questions. Then stop at gate 0 — present the mode recorded, the size, architecture and practices
proposed, the files created, the playback, the `assumed` entries and the questions — and wait for the
user's decisions and corrections before writing the product spec. When proposing the small track, draft
its page and stop there instead (`small-track.md`).
