---
name: spec-driven
description: Runs a project spec-first as small, linked, agent-readable files - discovery of every product and technical gray area, a product spec, numbered FR/NFR requirements in EARS form with a traceability matrix, a technical spec with ADRs and a researched stack playbook, a stepwise plan, then review with findings recorded in files. Keeps the specs living (later features are change folders merged on release), makes AGENTS.md - imported by CLAUDE.md - the entry point, and runs either one agent or a lead/coder loop that communicates through files, with the user approving every decision beyond the approved spec. Use when starting a new project or major feature, writing product or technical specs, requirements or ADRs, planning an implementation, setting up multi-agent or cross-tool work, handing work to another agent, or reviewing an implementation against its spec.
---

# Spec-driven development

Build the understanding before the code. The spec phases produce a **cook book**: a set of documents
complete enough that a different agent — on a different model, in a different tool, with none of the
conversation that produced them — can implement the project correctly, and split finely enough that it
loads only the pages its task needs.

That constraint is what makes this method worth the effort, and it is the bar every document is held
to. This skill builds on `senior-engineering`, which applies throughout; load both. Use the project's
own refactoring or cleanup skill when one exists.

Every checklist and example list here is a floor, not a fence: it names what is most often at stake,
never the edge of what to consider. Each project adds what its own domain, risks and architecture
demand. Design principles are the one exception: senior-engineering keeps them a small, fixed set.

## The pipeline

```
0. Setup and discovery  mode, size, architecture; understanding, gray areas       → AGENTS.md, docs/adr/, docs/discovery/
1. Product              what and why                                              → docs/specs/01-product/
2. Requirements         what exactly, how well                                    → docs/specs/02-requirements/
3. Tech spec            how — with ADRs and the stack playbook                    → docs/specs/03-tech/, docs/adr/, docs/engineering/
4. Plan                 in what order                                             → docs/changes/CH-NNN-<slug>/plan/
   ─────────────── handoff gate ───────────────
5. Implementation       one agent, or the lead/coder loop                         → code, docs/changes/CH-NNN-<slug>/tasks/
6. Review               against the spec and the code-quality lenses              → docs/changes/CH-NNN-<slug>/reviews/  ⇄ 5
7. Close                user accepts; merge into the living specs; archive        → docs/specs/, docs/changes/archive/
```

**Phases 1-4 run to completion before any implementation code is written.** When the plan is done, stop
and hand it back. The user decides whether to implement here, later, or elsewhere.

**The specs are living.** `docs/specs/` always describes the system as it is — or, before the first
release, as it is being built. A later major feature is a *change*: its product, requirement and design
deltas, its plan, tasks and reviews live in its change folder, and are merged into the living specs when
it ships (`references/changes.md`).

**Scale the ceremony to the change.** The full pipeline is for a new project or a major feature. A small
change needs no change folder and no separate plan: run senior-engineering's product pass, add or amend
the affected requirements and design items in the living specs — ids, EARS statements, the traceability
row — in the same edit as the code, and report it as one step. Heavy process on small work is how
spec-driven development gets abandoned. The project's own weight — its size, architecture and the
practices it uses — is decided once, at setup, with the user.

## Ask the operating mode first

Before phase 1, ask the user whether the project runs with **one agent** or **several** — for example a
lead that acts as product manager, tech lead, architect and reviewer, plus a coder that implements —
and which tool each agent runs in. Record the answer in `AGENTS.md`. In multi-agent mode the agents
communicate only through files, the user can step in at any point, and `references/multi-agent.md`
governs the loop.

Then, from discovery's answers, propose the project's **size, architecture and practices** — a
monolith is the usual start, a modular monolith where a later split is plausible, services only for a
stated need (`references/setup.md`). The user decides at gate 0; it is recorded in `AGENTS.md` and the
first ADR, and every later phase follows it.

## Every document is small, focused and linked

A single long specification is expensive for an agent to load and mostly irrelevant to any one task.
Every phase, in every pipeline stage, writes **a folder of topic files**, never one big document:

- **One topic per file.** Target 80–200 lines; **hard cap 300**. A file over 100 lines opens with a
  contents list.
- **Author topic files from the start** — never a monolith chopped up afterwards.
- **Every file opens with a header** — status, a one-line summary, ids, related files — so its first
  lines tell a reader whether to read on.
- **Every living document is reachable from `AGENTS.md` in two hops**: `AGENTS.md` → an index (the specs
  manifest, the ADR index, the engineering index) → the file. A change folder is reached through the
  changes index, and inside it the plan index lists its steps and tasks.
- **Stable ids in headings** — `FR-`, `NFR-`, `ADR-`, `Q-`, `P-`, `C-`, `J-`, `FL-`, `RL-`, `CH-`, plus
  ids scoped to a change such as `CH-007/S-02` — and cross-references by id plus the path from the
  repository root.
- **Every plan step and task brief names the exact files it needs**, so nobody reads the whole bundle.

`AGENTS.md` describes the project and points into the specs; the specs point into their sub-files; a new
agent understands the whole project by following the links instead of reading everything. The full
rules, and the `AGENTS.md` and `CLAUDE.md` templates, are in
`../senior-engineering/references/project-knowledge.md`.

## Load the phase you are in

Read the files for the current phase, not all of them.

| Phase | Read |
|---|---|
| 0 — Setup | `references/setup.md`, `../senior-engineering/references/project-knowledge.md` |
| 0 — Discovery, and at every gate | `references/discovery.md` |
| 1 — Product spec | `references/product-spec.md` |
| 2 — Requirements | `references/requirements.md` |
| 3 — Tech spec | `references/tech-spec-structure.md`, then `references/tech-spec-behaviour.md`; `../senior-engineering/references/decision-records.md` for ADRs; `../senior-engineering/references/modern-practices.md` for the stack playbook |
| 4 — Plan | `references/plan.md` |
| A later change, any phase | `references/changes.md`, with that phase's file |
| Multi-agent work | `references/multi-agent.md`, `references/handoff-templates.md` |
| 5 — Implementation | the plan step and the files it lists, plus `senior-engineering` |
| 6 — Review | `references/review.md`, `../senior-engineering/references/review.md`, `../senior-engineering/references/security.md`, `../senior-engineering/references/testing.md` |
| 7 — Close | `references/changes.md` |

## The handoff contract

Every document satisfies all of these. A document that fails any of them is not finished, however long
it is.

- **Self-contained for its topic.** No "as we discussed", "the approach above", "the usual pattern", or
  reference to anything outside the repository. Other files are cited by id and relative path.
- **No pronouns pointing at the conversation.** The reader was not there.
- **Every decision carries its reason** — in the document for a small one, in an ADR for a significant
  one. A decision without a rationale gets silently reversed by the next reader who prefers something
  else.
- **No `TBD`, no `etc.`, no "to be determined during implementation".** Either decide it, or record it in
  the gray-area register and cite its `Q-` id where the doubt sits — escalate, do not guess. An
  implementer must never have to invent a requirement.
- **Concrete over descriptive.** Not "store the amount" but the field, its type, its precision, its
  nullability, and its unit. Not "handle errors" but which error, what the caller sees, what is logged,
  what is stored.
- **Terms are defined once, in the glossary, and used consistently.** Two words for one concept is how two
  implementations of it get built.
- **Everything downstream of phase 2 cites requirement ids.** Components, flows, plan steps, briefs and
  review findings name the `FR-`/`NFR-` they serve, and the traceability matrix is the one place coverage
  is recorded.
- **Small and findable.** Within the size budget, opening with its header, listed in its index.

Before declaring a phase done, run this test: *if I handed only these files to a competent stranger, in
another tool, what would they have to ask me?* Every answer is a gap. Fix it, or record it in the
register.

## Working method for the spec phases

**Understand both sides completely.** Sweep the product side and the technical side, play your
understanding back to the user, and keep every ambiguity in the gray-area register until it is resolved
(`references/discovery.md`). Ask about every gray area whose answer changes the work.

**Draft, then challenge.** Do not interrogate the user from a blank page, and do not invent requirements
to fill silence. Write a first pass from what you have been told, marking every inference, then come back
with targeted questions on the gaps that actually matter.

**Batch questions.** Do the whole draft, collect what is genuinely unresolved, and ask the few that matter
most at once, each with real options, trade-offs and your recommendation. Decide the routine points
yourself, record them as `assumed`, and list them at the gate. A question per paragraph is exhausting and
trains the user to stop reading.

**Separate what you know from what you assumed.** Every assumption is an `assumed` entry in the
register, listed at the next gate — a thing the user can correct cheaply before anything depends on it.

**Research, think, propose.** For design and solution choices, research current practice across several
kinds of source and synthesize. Bring better approaches and creative alternatives — as entries in the
proposal register. **Hard rule: a proposal is never built until the user accepts it.**

**Write no implementation code during phases 1-4.** Sketching a type signature or a schema fragment
inside the tech spec is the spec; creating project files is not. Research is the exception: to check a
library's behaviour, or to put a real number on an NFR, build a throwaway probe in a scratch directory,
keep the number, and say that is what you did.

## Order matters, and so does separation

- **The product spec contains no technology.** No framework, no database, no library. If a sentence names
  one, it belongs in the tech spec. This keeps product decisions from being quietly driven by an
  implementation preference.
- **The requirements contain no solution language either**, and no requirement without a source in the
  product spec. They are the product spec made countable and checkable, not a second draft of it.
- **The tech spec contains no product decisions and no new requirements.** If writing it surfaces a
  product question — what should happen when two users claim the same slot — that goes back to phase 1
  and forward through phase 2. If it surfaces a missing requirement, add it in phase 2 rather than burying
  it in a design paragraph.
- **The plan contains no new decisions at all.** It is an ordering of work already specified. If a step
  needs a decision, the tech spec is incomplete; fix it there.

Each phase may send you back to an earlier one. That is the method working, not a failure — the cost of
going back one document is trivial compared with discovering it during implementation.

## Gates

**Gate 0 — after setup and the first discovery pass:** present the operating mode, the size,
architecture and practices proposed, the files created, the playback of your understanding, and the
first batch of questions. Wait for the user's corrections
before writing the product spec.

**After each of phases 1 to 4: stop and present.** Summarize what the documents decide; list the
`assumed` entries for confirmation, the open questions, the ADRs awaiting a decision, and the new
proposals; ask for approval or corrections. Do not roll straight into the next phase.

**At the tech-spec and plan gates, run a pre-mortem first** (`references/discovery.md`) and present its
list with the summary.

**After phase 4: hand off.** State that the specs and plan are complete, where they are — the manifest and
the change folder — and what an implementing agent should read first. In multi-agent mode, the lead now
writes the first briefs. Do not begin implementing unless the user asks you to.

**During implementation (phase 5):** work the plan step by step, in order. After each step, verify it as
the plan specifies, record the result in the step file, and fill in its traceability cells. Do not batch
several steps and verify at the end, and do not improvise work that is not in the plan — if the plan is
wrong, say so and amend it. In multi-agent mode the loop in `references/multi-agent.md` does this.

**Review (phase 6)** may be run by any agent the user chooses — the spec author, the implementer, or a
fresh one. Write it so it works for a reviewer with no context: it reads the files and the code. Findings
are recorded to files, not just reported in chat, so the loop survives a new session.

**Close (phase 7):** after the review is closed and the user has accepted the change, merge it into the
living specs and archive its folder (`references/changes.md`).

## Amending an approved spec

Specs drift. When implementation reveals the spec is wrong, that is a **finding against the spec**, not a
licence to diverge.

1. Stop and say what the spec got wrong, and propose the amendment.
2. With the user's yes, amend the document, keeping the superseded decision visible with the reason it
   changed — a superseding ADR where it was an ADR's decision. Do not quietly overwrite history; the
   rejected reason is what stops it being re-proposed.
3. Then continue.

Code that silently disagrees with an approved spec is the worst outcome of this method, because the
document is now actively misleading — worse than having no document.

## Anti-patterns

| Symptom | What it means |
|---|---|
| Spec full of `TBD` | Decisions deferred to whoever is least equipped to make them |
| One 900-line spec file | Every task pays to load all of it; split it by topic |
| A monolith chopped into parts afterwards | Fragments that cut across topics; design files for how they are loaded |
| `AGENTS.md` importing specs, or restating the directory tree | Everything loads at startup, and the tree was derivable anyway |
| A brief that says "see the tech spec" | The implementer reads everything; name the files |
| A brief that copies spec text | Two sources of truth; the copy drifts |
| Tech spec naming no versions | "Latest" is not reproducible |
| Decision rationale in the tech spec as well as the ADR | Two places to update; one will be stale |
| An accepted ADR edited in place | The rejected reasoning is lost; supersede it instead |
| A proposal that is already implemented when presented | Scope taken, not asked |
| Living specs describing a feature not yet built | Readers can no longer trust them; that is what the change folder is for |
| A change closed without merging its deltas | The living specs now lie about the system |
| The lead writing code, or the coder editing specs | Ownership broken; neither file can be trusted |
| A review round that adds new requirements | Moving goalposts; the loop never ends |
| Flow with only a happy path | The failure behaviour will be invented under pressure |
| Integration test against an in-memory substitute | Passes exactly where production fails |
| Plan step verified by "it builds" | Not a verification |
| Plan step that touches "wherever needed" | The component inventory is incomplete |
| Product spec naming a database | Solution chosen before the problem was stated |
| A step whose result is checked three steps later | Wrong step boundaries |
| Findings reported only in chat | Lost at the end of the session |
| "The implementer can decide" | Either specify it or record it as a question — escalate, do not guess |
| NFR with no number | A wish; it will be declared met by whoever is asked |
| A `Must` requirement with no plan step | Unimplemented, and invisible without the matrix |
| Requirement with no product-spec source | Invented scope, or an incomplete product spec |
| An NFR category left silent | Not "not applicable" — just undiscovered until production |
| "Verified" on an NFR whose mechanism was checked but outcome was not | Two different claims |
