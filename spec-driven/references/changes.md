# Changes — living specs and change folders

**Goal:** the living specs always tell the truth about the system, while work in flight stays visible,
reviewable, and separate from that truth until it ships.

## Contents
- Living specs versus changes
- When to open a change
- The change folder
- Writing deltas
- IDs across changes
- Closing a change: merge and archive
- Concurrent changes

## Living specs versus changes

- **`docs/specs/` is what the system does now.** A reader can trust it without first checking which
  features are still being built — that trust is the whole point, and a new agent learns the system by
  reading one bundle, however long the project's history.
- **`docs/changes/CH-NNN-<slug>/` is what will change, why, and how it is being built.**
- **The initial build is CH-001**: its product, requirements and tech spec are written straight into
  `docs/specs/`; its plan, tasks and reviews live in its change folder. Every change after that writes
  deltas against the living specs.

## When to open a change

Open one for a major feature, a breaking change to a contract, schema or behaviour others rely on, or
anything that needs more than one plan step — or wherever the project's practices set the line.
Anything smaller — a bug fix, a hotfix, an added field — amends the living spec directly, in the same
edit as the code: no folder, no ceremony.

## The change folder

```
docs/changes/CH-007-peak-pricing/
  proposal.md        why, what changes, affected capabilities, scope in and out, links, status
  product.md         product deltas, if the change affects the product spec
  requirements.md    requirement deltas — split into requirements/<capability>.md past 300 lines
  tech.md            design deltas — split into tech/<topic>.md past 300 lines
  plan/              README.md (the plan index) and steps/ — see plan.md
  tasks/             multi-agent task folders: reports and reviews — see multi-agent.md
  reviews/           review files — see review.md
```

`proposal.md`:

```markdown
# CH-007 — Peak pricing
Status: proposed | approved | in progress | in review | merged | archived | rejected
Opened: YYYY-MM-DD · Owner: <lead / agent>
Summary: <one or two sentences>

## Why
The problem, and the proposal or request it comes from (P-, Q-, a user request).
## What changes
Capabilities and journeys affected (C-, J-); requirements added, modified or removed (by id).
## Out of scope
## Impact
Data and migrations, contracts and clients, security posture, operations.
## Decisions
ADRs proposed or superseded by this change.
```

## Writing deltas

Deltas are written against the living spec, item by item, by id:

```markdown
## ADDED
### FR-031 — Peak-season cancellation window
<the complete requirement block>

## MODIFIED
### FR-014 — Free cancellation window
Was: free until 24 h before check-in.
<the complete requirement block, restated in full>

## REMOVED
### FR-009 — Manual rate override
Reason: replaced by FR-031.

## RENAMED
FR-011: "Booking hold" → "Tentative booking"
```

- **MODIFIED restates the whole item**, so merging means replacing, not patching.
- **The same four sections work for every kind of item** — capabilities and journeys, glossary terms,
  flows, rules, aggregates, tables, contracts, components.
- **Each delta file keeps its own small traceability table** for the items it adds or modifies; the
  tech-spec deltas and the plan fill it in, and it is merged into the living matrix at close.
- **From CH-002 on, nothing this change adds or modifies is written to `docs/specs/` while it is
  open** — only the merge at close writes there. (CH-001 writes the first living specs directly; see
  above.) A small fix made meanwhile amends the living specs directly, and the change reconciles
  against it at close ("Concurrent changes").

## IDs across changes

New items continue the global sequence. Before allocating an id, search `docs/specs/` and every open
change folder for the highest one in use. One writer allocates ids — the lead, in multi-agent mode — so
parallel changes cannot collide. An id is never reused, not even from a rejected change.

## Closing a change: merge and archive

This is phase 7, and it runs in this order — never before the review:

1. Every step is done, the change's review (phase 6) is closed, and the user has accepted the
   change.
2. Apply each delta to the living specs: ADDED items go where their topic lives; MODIFIED items replace
   the original; REMOVED items stay with status `retired` and the reason; RENAMED items are updated
   everywhere — search for the old name.
3. Merge the change's traceability rows into the living matrix — their plan-step cells
   (`CH-NNN/S-NN`) record which change implemented each — and update the glossary, the manifest and
   the ADR index.
4. Re-check the merged files against the "Done when" lists in `product-spec.md`, `requirements.md` and
   `tech-spec-behaviour.md` ("Quality bars") — nothing may still point at the change as pending.
5. Move the folder to `docs/changes/archive/YYYY-MM-DD-CH-NNN-<slug>/` and update
   `docs/changes/README.md`. Documents outside the folder cite a change by its id (`CH-007`,
   `CH-007/S-02`), never by folder path, so their references survive the move.

A change that is closed without the merge leaves the living specs lying about the system — the worst
outcome of this method, because everyone who reads them next is misled.

## Concurrent changes

Two open changes may touch the same item. The second to close reconciles against the merged result,
like a code merge conflict. A MODIFIED delta whose "Was" no longer matches the living spec is a conflict
to resolve with the user — never an overwrite.
