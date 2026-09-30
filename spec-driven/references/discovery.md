# Discovery — understanding, gray areas and ideas

**Goal:** understand the product side and the technical side completely before specifying; keep every
ambiguity visible until it is resolved; and bring ideas to the user without ever adopting one alone.
Discovery opens the project and returns at every gate.

## Contents
- Why this has its own step
- Sweep both sides
- Play back your understanding
- The gray-area register
- How to ask
- Techniques that surface what nobody said
- Research
- The proposal register
- Pre-mortem

## Why this has its own step

Studies of coding models find that, given an underspecified task, most responses start producing
instead of asking — and that when the model does ask, results improve substantially. The cheapest moment to resolve an ambiguity is before anything
depends on it: a wrong assumption here costs a paragraph; the same assumption in code costs a rewrite.

## Sweep both sides

Work through both lists against everything you have been told and everything already in the repository.
Every item ends up **known** (with its source), **assumed** (your stated default, flagged for
confirmation), or **asked**.

**Product side** — the roles and the job each is trying to get done; the problem today and what it
costs; the business rules and their exceptions; edge cases; what users see when something fails;
volumes and growth; money, time and units; legal, regulatory and contractual constraints; obligatory
integrations; how success is measured; what is out of scope.

**Technical side** — existing systems, code and data (migration?); integrations and their real
contracts; environments, hosting and who operates them; what the team already runs; quality targets —
latency, availability, scale; security and privacy — data classes, identity, authorization model;
constraints on the stack; deadlines; who approves what.

## Play back your understanding

Write `docs/discovery/understanding.md` (under 200 lines): the product understanding and the technical
understanding in your own words, each point marked *confirmed* or *inferred*. Ask the user to correct
it. A playback catches the misunderstanding that no individual question would, because it shows the
whole picture you are about to build on.

## The gray-area register

`docs/discovery/questions.md` holds every ambiguity, from any phase, until it is resolved.

```markdown
### Q-012 — <the question>
Status: open | answered | assumed | deferred | obsolete | superseded by Q-NNN · Raised: YYYY-MM-DD by <agent/role> · Area: <product | technical | security | …>
Why it matters: <what it blocks or changes>
Options: A — <…> · B — <…> · Recommended: A, because <…>
Answer: <…> — by <the user | lead, within the approved spec>, YYYY-MM-DD
Assumed: <the default taken> — confirm by: <gate or date>        (only when status is assumed)
Applied to: <FR-/ADR-/file>
```

- **Every would-be `TBD` becomes an entry**, and the document cites it where the doubt sits — `[Q-012]`.
  A document carrying an open `Q-` citation cannot be approved.
- **`assumed`** means you decided a routine point yourself. Every assumed entry is listed at the next
  gate for the user to confirm or correct — cheaply, before anything depends on it.
- **A changed answer is a new entry** that supersedes the old one; the history stays readable.
- **Who may answer**: the user; the lead agent only where the approved spec already answers it.
- Open and assumed entries first. When the file passes 300 lines, move the closed ones — answered and
  applied, obsolete, superseded — to `docs/discovery/questions-archive.md`.

## How to ask

- **Draft, then ask.** Write the first pass from what you have, marking every inference, then ask about
  the gaps that actually matter. Never interrogate from a blank page.
- **Batch per round**: at most four or five questions — the ones with the most impact — each with real
  options, the trade-off, and your recommendation. Use the tool's question mechanism.
- **Ask when two readings lead to materially different work.** Decide the routine points yourself and
  record them as `assumed`.
- **Record every answer immediately**, in the register and in the documents it changes.

## Techniques that surface what nobody said

- **Example mapping**, per capability: rules become requirements, concrete examples become acceptance
  criteria, and unanswered points become `Q-` entries. Many questions means the capability is not ready;
  many rules means it is too big and should split.
- **Ask for the worked example.** "Show me one real booking, with its numbers" exposes rounding, time
  zones and edge cases faster than any abstract question.
- **Assumption mapping**: rate each assumption by importance and by the evidence behind it. Validate
  the important, weakly evidenced ones first.
- **Pre-mortem** — below.

## Research

When a question is a design or solution choice, research it across several kinds of source — vendor
documentation, standards, mature implementations in other ecosystems, issue trackers, package
registries, practitioner write-ups — and synthesize rather than list. Record the sources, what each
contributed and the date, in the ADR or the understanding file. Queries stay generic: no project
names, code or identifiers (senior-engineering `security.md`).

## The proposal register

`docs/discovery/proposals.md` holds every idea that goes beyond the approved scope — a product
improvement, a creative alternative, an optimization, a refactor, a new dependency, a better process —
from any agent, at any phase.

```markdown
### P-007 — <title>
Status: idea | proposed | accepted | rejected | deferred | withdrawn | implemented | superseded
Raised: YYYY-MM-DD by <agent/role> · Type: product | architecture | optimization | refactor | dependency | process
Problem and evidence: <…>
Proposal: <…> · Alternatives: <…, including doing nothing>
Benefit: <…> · Cost: <…> · Risk: <…> · Reversibility: <…> · Confidence: <…>
Spec impact: <the documents, requirements and ADRs that would change>
Decision: <accepted | rejected | deferred> — by the user, YYYY-MM-DD — <reason>
Implemented through: <FR-/ADR-/CH-> · Revisit when: <…>
```

An optimization or refactor adds three lines: **Where** (file and symbol) and **Found by** (the review
lens), and **Verification** — the equivalence tests, the before-and-after measurement, and how to roll
back. Its evidence is a measurement or an estimate at a stated data size, never a hunch.

- **Hard rule: nothing in this register is built until the user accepts it.** An accepted proposal
  enters the work by the normal route — a requirement, an ADR, a change, a plan step.
- **Keep rejections, with their reasons.** They stop the same idea coming back every month.
- **Present new proposals at the next gate**, never as a fait accompli in the middle of implementation.

## Pre-mortem

At the tech-spec gate and the plan gate, and before any risky change: assume the system shipped and
failed badly six months later. List the five to ten likeliest causes — product, technical, security,
operational. Each becomes a `Q-` entry, a risk in the product spec, a proposal, or a direct fix to the
draft. Present the list with the gate summary.
