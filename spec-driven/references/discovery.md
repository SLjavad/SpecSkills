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

The cheapest moment to resolve an ambiguity is before anything depends on it: a wrong assumption here
costs a paragraph; the same assumption in code costs a rewrite.

## Sweep both sides

Run senior-engineering's sweep ("Resolving ambiguity") against everything you have been told and
everything already in the repository. For a whole project, also cover: on the product side, the
problem today and what it costs, money, time and units, and how success is measured; on the technical
side, the logging, metrics, CI and secret storage already there, the expected lifespan, and whether any
part must scale or deploy separately. Every item ends up **known** (with its source), **assumed** (your
stated default, flagged for confirmation), or **asked**.

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
  An approved document cites no **unresolved** entry — any status but `answered`, or an `assumed`
  entry the user has not yet confirmed at a gate.
- **`assumed`** means you decided a routine point yourself. Every assumed entry is listed at the next
  gate for the user to confirm or correct — cheaply, before anything depends on it.
- **A changed answer is a new entry** that supersedes the old one; the history stays readable.
- **Who may answer**: the user; the lead agent only where the approved spec already answers it.
- Open and assumed entries first. When the file passes 300 lines, move the closed ones — answered and
  applied, obsolete, superseded — to `docs/discovery/questions-archive.md`.

## How to ask

As senior-engineering's "Resolving ambiguity" describes, with three additions: draft first — never
interrogate from a blank page; ask at most four questions per round, the ones with the most impact;
and record every answer immediately, in the register and in the documents it changes.

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

A design or solution choice is researched as senior-engineering's "Thinking beyond the ask" says, with
queries kept generic (`security.md`). Record the sources, what each contributed and the date, in the
ADR or the understanding file.

## The proposal register

`docs/discovery/proposals.md` holds every idea that goes beyond the approved scope — a product
improvement, a creative alternative, an optimization, a refactor, a new dependency, a better process —
from any agent, at any phase. Each entry, `### P-NNN — <title>`, uses the one proposal format in
senior-engineering's `references/review.md` ("Improvements are proposals").

- **`idea`** is noted but not yet worked up; it becomes `proposed` once its fields are filled in.
- **Hard rule: nothing in this register is built until the user accepts it.** An accepted proposal
  enters the work by the normal route — a requirement, an ADR, a change, a plan step.
- **Keep rejections, with their reasons.** They stop the same idea coming back every month.
- **Present new proposals at the next gate**, never as a fait accompli in the middle of implementation.

## Pre-mortem

At the tech-spec gate and the plan gate, and before any risky change: assume the system shipped and
failed badly six months later. List the five to ten likeliest causes — product, technical, security,
operational. Each becomes a `Q-` entry, a risk in the product spec, a proposal, or a direct fix to the
draft. Present the list with the gate summary.
