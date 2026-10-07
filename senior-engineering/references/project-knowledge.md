# Project knowledge

How a project describes itself so that any agent, in any tool, can understand it from the files alone
— loading only what the task at hand needs. Read when setting up a project, adding or reorganizing its
docs, or whenever a project has no `AGENTS.md`.

## Contents
- The hierarchy
- Size and sharding rules
- Headers, ids and links
- AGENTS.md template
- CLAUDE.md template
- Nested instructions and tool shims
- Engineering principles for agents without these skills
- Keeping it true

## The hierarchy

```
AGENTS.md                  entry point for every agent and tool — short, always loaded
CLAUDE.md                  @AGENTS.md, plus Claude-only notes
docs/specs/README.md       manifest of the living specs: every file, one line each
docs/changes/README.md     changes in flight, and archived
docs/adr/README.md         index of decisions
docs/discovery/            understanding, gray-area register, proposal register
docs/engineering/README.md index of stack playbooks, area records (areas/), principles
docs/handoff/              multi-agent protocol and board (only when used)
```

Every living document is reachable from `AGENTS.md` in two hops: `AGENTS.md` → an index → the file.
A change folder is reached through the changes index, and its plan index lists its steps and tasks. A
plan step links the exact files the task needs, so an implementer reads a handful of small files
instead of the whole bundle. That selective loading is where the token saving comes from.

## Size and sharding rules

- **One topic per file**, named for its topic: `booking-cancellation.md`, never `part-2.md`.
- **Target 80–200 lines; hard cap 300.** A file over 100 lines opens with a contents list, so a partial
  read still shows everything it holds.
- **Author topic files from the start.** A monolith chopped up afterwards produces fragments that cut
  across topics; design the files for how they will be loaded.
- **Split by sub-topic when a file passes the cap**, and update its index in the same edit. Merge two
  tiny files that are always read together.
- **Indexes stay under 150 lines.** An index lists a path and one line; it never restates content —
  not even a file's status, which lives only in that file's header.
- **Registers and logs archive rather than grow.** When an append-only file passes the cap, move closed
  entries to an archive file and keep the open ones.
- **`AGENTS.md` stays under 150 lines**, and the whole instruction chain a tool loads — root plus nested
  files — under roughly 24 KiB; some tools stop reading at a fixed size. Codex, for one, silently
  truncates past 32 KiB by default (checked September 2026) — check the tools the project uses.

## Headers, ids and links

Every document opens with its title and a short header, so its first lines tell a reader whether to
read on. A plan step is the one exception for status: its plan's progress table holds it.

```markdown
# Booking — functional requirements
Status: approved · Owner: lead · IDs: FR-010–FR-021
Summary: What guests and agents can do with a booking — create, change, cancel, view.
Related: docs/specs/03-tech/domain/booking.md · docs/specs/03-tech/flows/FL-03-cancel-booking.md
```

- **Stable ids for everything that gets cited**: `FR-` and `NFR-` (three digits), `ADR-` (four), `Q-`,
  `P-`, `C-` (capability), `J-` (journey), `FL-` (flow), `RL-` (rule), `TH-` (threat), `CH-` (change).
  The id appears in the heading that defines the item, so a text search finds exactly one definition.
  Never renumber, never reuse; a removed item keeps its id with status `retired` and the reason.
- **Scoped ids** are unique only inside their parent and are cited with it: plan steps `S-` and
  findings `F-` inside a change (`CH-007/S-02`, `CH-007/F-12`), reviews `R-` inside a change,
  acceptance criteria under their requirement (`AC-014.1`).
- **Cross-reference by id plus the path from the repository root** —
  `FR-014` (`docs/specs/02-requirements/functional/booking.md`) — never "the section above", never a
  section number, never `../..`. The same string then refers to a file everywhere, so one search finds
  every reference when a file moves, and no agent has to work out where a relative path lands. Cite a
  change by its id, since its folder moves when it is archived.
- **Forward slashes, and no tool-specific include syntax** in `AGENTS.md` or the docs. In `CLAUDE.md`
  an `@path` import loads that file at startup, which defeats the point of small files; the only import
  is `@AGENTS.md` itself.
- **Diagrams as text** — Mermaid, in the subset the project's repository host renders; at the time of
  writing GitHub and Azure DevOps share `sequenceDiagram`, `stateDiagram-v2`, `erDiagram`,
  `classDiagram` and `graph`, but not `flowchart` or the experimental C4 syntax — draw C4 levels as
  `graph` with C4 labels. Check the host's current documentation.

## AGENTS.md template

Carry what an agent cannot derive from the code: the purpose, the commands, the non-obvious rules, and
where the knowledge lives. Leave out directory trees, dependency lists and architecture overviews — an
agent can list the repository itself, and context files padded with derivable detail cost tokens
without improving results.

```markdown
# <Project>
<Two to four sentences: what the system is, who uses it, why it exists.>

## Commands
Build: `…` · Test: `…` · Run: `…` · Lint/format: `…` · Migrate: `…`
Integration tests need: <e.g. Docker running>

## Where the knowledge lives
- Specs, the current truth: docs/specs/README.md
- Changes in flight: docs/changes/README.md
- Decisions: docs/adr/README.md
- Product and technical context: docs/discovery/understanding.md
- Open questions and proposals: docs/discovery/questions.md, docs/discovery/proposals.md
- How we write code here — stack playbooks, area records: docs/engineering/README.md

## Working mode
<single agent | lead + coder> · Lead: <tool> · Coder: <tool>
Size: <small | standard> · Track: <small | standard> · Architecture: <shape, style> — docs/adr/0001-<slug>.md
Practices: <file merging, ADR form, when a change gets its own folder, mutation / architecture / load tests>
Multi-agent: every agent starts at docs/handoff/PROTOCOL.md.

## Rules for this project
- <the project's own non-obvious conventions, one line each>

## Engineering baseline
Agents with the senior-engineering and spec-driven skills installed: use them.
Every other agent: read docs/engineering/principles.md before changing anything.
```

The baseline rules — asking, proposals, data egress, tests, standing defaults, git — live in the
skills, or in `principles.md` for agents without them; `AGENTS.md` does not repeat them.

Add each line when its target exists — no links to files nobody has written, and no `Commands` section
until the commands exist.

## CLAUDE.md template

```markdown
@AGENTS.md

## Claude Code
- Skills, where installed: senior-engineering (always), spec-driven (specs, plans, reviews, multi-agent
  work).
- <Claude-only notes: MCP servers to prefer, plan-mode areas, permission notes.>
```

Under its default settings, Claude Code reads a root `AGENTS.md` by itself only when no `CLAUDE.md`
exists; with a `CLAUDE.md`, the `@AGENTS.md` import is what loads it (check its current memory
documentation if behaviour seems different). Telling the agent in prose to "read AGENTS.md" is not
reliable — it may never open the file. On Windows, use the import, not a symlink.

## Nested instructions and tool shims

- **A nested `AGENTS.md`** adds rules for its subtree. Keep it under about 80 lines and additive only —
  tools disagree about precedence, so a nested file must never contradict its parent. Pair it with a
  one-line `CLAUDE.md` (`@AGENTS.md`) so Claude Code loads it too.
- **A tool that does not read `AGENTS.md`** — some IDE chat integrations read only their own
  instructions file — gets a short shim in that file, pointing to `AGENTS.md` and, in multi-agent work,
  to `docs/handoff/PROTOCOL.md`. Check the tool's current documentation for which file it reads.

## Engineering principles for agents without these skills

At setup, write `docs/engineering/principles.md`, under 200 lines, distilled from senior-engineering
for this project — the one home of the baseline for any agent without these skills, in any tool, on
any machine, since `AGENTS.md` does not repeat it. Record the date and the skill it came from, and
refresh it when the skill changes.

```markdown
# Engineering principles
Status: current · Distilled from: senior-engineering, YYYY-MM-DD · Owner: lead
Summary: The rules every agent follows on this project, whatever tool it runs in.

## Non-negotiables            ask instead of guessing; no silent behaviour change; propose, never
                              smuggle; security is correctness; confidential data never goes to remote
                              tools; check the pinned versions; evidence before assertions; git and
                              migration rules; risk lists are a floor, not a fence
## Standing defaults           no commercial tools unless named; the stack's version and test-framework
                              defaults (for .NET: latest stable release, xUnit)
## Design                      dependency rule; SOLID, DRY and KISS/YAGNI only, the simpler design
                              winning; over-engineering counts as a defect; rich domain
                              entities and what stays plain; failure design; the architecture tests
## Tests                       the four lenses — business, technical, performance, security — plus the
                              flow's other risks; Testcontainers for every external dependency; see it
                              fail first; never weaken a test; mutation testing on the core
## Security                    the design and implementation rules that apply here; the data-egress rules
## Before reporting            the self-review checklist and what the report contains
## Where to look               the stack playbook, the handoff protocol, the area records
```

## Keeping it true

- **Update the docs a change affects in the same change.** Code that disagrees with an approved document
  makes the document actively misleading — worse than having no document.
- **Every added, renamed or removed document updates its index** in the same edit.
- **Delete what a change made false** rather than writing around it.
