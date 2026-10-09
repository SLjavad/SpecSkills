# Small track

**Goal:** the same thinking as the full pipeline — understand both sides, keep product apart from
technology, make every requirement checkable, decide before building, verify every step — in three spec
files and two approval stops, so a small project gets the method without the weight that gets it
abandoned.

This file overrides the phase files where they differ. Read it first, then the phase file for the part
you are writing, and skip what this file drops.

## Contents
- When it applies
- What never relaxes
- Two stops instead of five
- The files
- Phase by phase
- Later changes
- Outgrowing it

## When it applies

The small track is the practice set for a project sized **small** by the checklist in `setup.md`: one
deployable, about five capabilities or fewer, no stated need to scale far, and no obligation that needs
a formal record of decisions. Propose it with the size; the user decides, and `AGENTS.md` records it
under "Working mode" (`Size: small · Track: small`).

**Re-check at stop 1.** Count the capabilities in the drafted `product.md` against the checklist, and
name any mismatch with the size proposed.

## What never relaxes

Everything else — the skill, senior-engineering and each phase file — applies unchanged; size is not
stakes (`setup.md`). Merging files merges sections, never their content: the product file still names
no technology, the requirements no solution, and the plan makes no decisions.

## Two stops instead of five

| Stop | Presents | Replaces |
|---|---|---|
| **1 — What** | the mode; the size, track and architecture (the first ADR); the stack proposal; `product.md` and `requirements.md`; the `assumed` entries; at most four questions | gate 0 and the gates after phases 1 and 2 |
| **2 — How** | `tech.md` and its ADRs; the plan; the pre-mortem; how many `Must` requirements have a step; the `assumed` entries and open questions | the gates after phases 3 and 4 |

- **Draft through to stop 1 without waiting**, marking every inference — "draft, then challenge" at the
  scale of the whole front end. Stop earlier only when a question blocks the draft itself, such as what
  the product is or who it is for: ask that alone, then continue.
- **Propose the stack at stop 1**, as a `proposed` ADR built from the architecturally significant NFRs
  in `requirements.md`, so `tech.md` is written against a stack the user chose. It stays out of
  `product.md` and `requirements.md`.
- **If the user chooses the standard track at stop 1**, the drafts split into the standard files; no
  content is lost.

## The files

```
AGENTS.md, CLAUDE.md                  senior-engineering project-knowledge.md templates
docs/specs/product.md                 context, overview, users, capabilities, journeys, scope,
                                      success, scale, risks, glossary — one section each
docs/specs/requirements.md            FRs, NFRs, and the coverage table
docs/specs/tech.md                    stack, architecture, domain and data, contracts, flows and
                                      rules, cross-cutting, how NFRs are met, tests, security
docs/changes/CH-001-initial-build.md  the plan, then the review
docs/adr/                             README.md and the ADRs, short form
docs/discovery/questions.md, proposals.md     each created with its first entry
docs/engineering/principles.md        the baseline for agents without these skills
```

- **`AGENTS.md` links these files directly**, so there is no specs manifest or changes index while the
  specs are three files. Every file opens with its header, and one over 100 lines with a contents list.
- **Ids stay in the section headings**, so a section can later move into its own file unchanged; the
  edit that moves it updates every citation of its path.

## Phase by phase

**Setup and discovery** (`setup.md`, `discovery.md`). Ask the mode; recommend one agent. A lead and a
coder work as `multi-agent.md` describes; its protocol's "Small track" line says where the step and its
task folder live.
Sweep both sides in full — it is cheap, and it is where small projects go wrong. The playback is the
*Context* section of `product.md`, each point marked confirmed or inferred, instead of a separate
`understanding.md`.

**Product — `product.md`** (`product-spec.md`). The sections of that file's table, each a section here;
the glossary is the last one. The primary journey and at most two secondary ones, each with what the
user sees when it fails. Its "Done when" applies, section by section.

**Requirements — `requirements.md`** (`requirements.md`). One compact block per requirement, grouped by
capability:

```markdown
### FR-014 — Free cancellation window
Must · Source: C-03, J-02 · Verification: test
When a guest cancels more than 24 hours before check-in, the system shall refund the full amount.
- AC-014.1 Check-in in 30 h → full refund; booking Cancelled.
- AC-014.2 Check-in in exactly 24 h → the fee applies (FR-015).
Fails: refund provider down → booking stays Paid; the guest sees "try again later"; nothing charged.
```

NFRs take the same shape with a target number, a measurement and a consequence if missed — only for the
categories with a real target. The rest go on one line, each with its reason: `Not applicable:
Scalability — one office, 20 users; Internationalisation — English only; …`. The ASVS level is still
chosen with the user. The file ends with the **coverage table**, which replaces the traceability matrix
and, like it, is filled in at planning and not touched during implementation:

```markdown
| ID | Priority | Plan step |
|---|---|---|
| FR-014 | Must | CH-001/S-03 |
```

The Plan step cell takes the same values as the matrix's (`requirements.md`).

**Tech — `tech.md`** (`tech-spec-structure.md`, `tech-spec-behaviour.md`).
- *Stack*: that file's table, versions pinned, then **stack notes** — the playbook (senior-engineering
  `modern-practices.md`) cut to what this project uses: support dates, what not to generate, the test
  toolchain, sourced and dated. It moves to `docs/engineering/stack-<name>.md` past about 80 lines.
- *Architecture*: modules and the dependency direction in a few lines; a diagram past three modules;
  architecture tests only where a boundary is worth enforcing.
- *Domain and data*: one section per aggregate with its tables. The quality bars on types, nulls,
  indexes and constraints all apply — this is where vagueness costs most.
- *Contracts*: endpoints and the error taxonomy in one section.
- *Flows and rules*: only the significant flows — a write, money, a trust boundary, an external call —
  each with its failure per step, and idempotency and concurrency decided where a duplicate or
  contention can do harm, or one line saying why not. Every rule with its worked example.
- *Cross-cutting*: the concerns that apply; the rest on one `Not applicable` line.
- *How NFRs are met*: the mechanism table, one row per NFR.
- *Tests*: the levels this project uses, the rest one line each; mutation testing where there is a core
  of hard rules.
- *Security*: the data classes and one threat table for the whole system, a row per threat at each
  boundary; every mitigation with its requirement and its test.
- *Decisions*: ADRs for the architecture and the stack — the stack may be one ADR as a whole — and for
  anything that meets senior-engineering's "When a decision needs an ADR". Other choices are notes in
  `tech.md`, with their reason.

**Plan — the CH-001 file** (`plan.md`). Sections: *Read first*, *Conventions* (the commands), *Steps*,
*Amendment log*. Its ordering rules all apply — a skeleton that runs first, vertical slices, riskiest
first, each step verifiable on its own, no decisions. One compact block per step:

```markdown
### S-03 — Cancel within the free window
Implements: FR-014, FR-015 · Depends on: S-02 · Status: planned
Files: src/Booking/… · tests/Booking/… · Read first: tech.md (Booking, FL-02), requirements.md (C-03)
Latitude: internal structure and naming within Booking
Tests: business — the 24 h boundary, both sides; failure — refund provider down (Testcontainers mock)
Verification: `<test command>` → the six cancellation tests pass, including WindowBoundaryAt24h
Result:
```

With every step in one file there is no separate progress table: each block's `Status:` line is the
step's one status, and its `Result:` the one record of what ran. In multi-agent mode the lead alone
writes that `Status:` line, with the protocol's values, and the task's report holds the result instead
(`multi-agent.md`).

The pre-mortem runs once, at stop 2.

**Implementation, review and close.** The step loop is unchanged. The review runs every lens in
`review.md` — security always — starting at the coverage table, and writes its findings in that
file's format into a *Review* section of the change file, split into `CH-001-review.md` past the cap.
When the user accepts, the change file moves to `docs/changes/archive/YYYY-MM-DD-CH-001-initial-build.md`.

## Later changes

- **A small change** amends the three spec files in the same edit as the code, as the skill describes.
- **A feature needing more than one step** gets one file, `docs/changes/CH-NNN-<slug>.md`: why, the
  deltas in the four sections of `changes.md`, the steps, then the review. It is merged into the spec
  files at close and archived. `AGENTS.md` links the open change.

## Outgrowing it

- **A spec file past 300 lines** splits into the standard layout for its phase — the phase file's "The
  files" table — and `docs/specs/README.md` is created as the manifest, in the same edit.
- **A project that is no longer small** moves to the standard track by a superseding ADR, with the
  user's yes; the new practices apply forward (`setup.md`).
