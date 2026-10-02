# Phase 1 — Product spec

**Goal:** a reader who knows nothing about this project can say what it is, who it serves, what problem
it removes, and how you will know it worked.

**Hard rule: no technology in these files.** No framework, language, database, library, hosting or
protocol. If a sentence names one, move it to the tech spec. A product spec that has already chosen a
database has skipped the thinking this phase exists for. The one exception is a technology the product
is *required* to use — an interchange standard its customers mandate, an existing system it must
integrate with. That is not a design choice: record it in `scope.md` as a CONSTRAINT, with its source.

Write to `docs/specs/01-product/` — or, for a later change, as product deltas in the change folder
(`changes.md`).

## Contents
- What to establish
- The files
- The glossary is not optional
- Done when
- Then stop

## What to establish

Work through these. Draft an answer for each from what you have been told and from
`docs/discovery/understanding.md`, mark what you inferred, then ask about the gaps that would change
the work (`discovery.md`).

**Purpose**
- What is this, in one paragraph a non-specialist understands?
- What problem does it remove, for whom? Describe the situation *today* and what it costs — in time,
  money, errors, or lost work. A problem with no stated cost cannot be prioritised.
- What value is created, and who receives it? Distinguish the buyer from the user when they differ.
- What is the single outcome that would make this a success? One, not five.

**Users**
- Who are the distinct roles? Name each and what they are trying to get done.
- Which role is primary? Designs that serve everyone equally usually serve the primary user badly.
- What does each role already use to solve this, and why is that inadequate? "Nothing" is a real
  answer and a warning sign.
- Who else is affected without using it — operators, support, finance, auditors? These are the users
  who surface late and expensively.

**Capabilities**
- What services or capabilities does the product offer? One line each, in the user's language, phrased
  as something they can do.
- For each: which role uses it, how often, and what happens if it is unavailable.
- Which capabilities are the product, and which are supporting? If everything is essential, scope has
  not been decided.

**Journeys**
- The primary journey end to end, in numbered steps, in user language — no components, no calls.
- The two or three most important secondary journeys.
- For each: what the user sees when it goes wrong, and what they can do next. This is a product
  decision and the most commonly skipped one.

**Boundaries**
- In scope, out of scope, and explicitly later. The "out" list is what prevents scope creep, so it must
  be written down even when it feels obvious.
- What must this integrate with, and is that an obligation or a preference?
- What are the real constraints — legal, regulatory, contractual, existing systems?
  Mark each as constraint or preference; a preference can be traded, a constraint cannot.
- What data does it handle that is personal, financial or confidential? The tech spec's security design
  starts from this list.

**Reality checks**
- How is success measured, with what number, observed where? "Users are happier" is not measurable.
- What has to be true for this to work that is not under your control?
- What is the biggest risk, and what would you do if it happened?
- Volume and scale expectations, in the user's terms: how many users, how many transactions, how much
  data, growing how fast. The tech spec cannot be sized without this.

## The files

One topic per file, each opening with the standard header (status, summary, ids, related):

| File | Holds |
|---|---|
| `overview.md` | Summary in one paragraph; the problem today and its cost; the value and who receives it; the single primary success outcome |
| `users.md` | Each role: name, what they are trying to do, primary or secondary, what they use today; the people affected without using it |
| `capabilities.md` | One `C-NN` block per capability: one line in user language, the role, frequency, impact if unavailable, core or supporting |
| `journeys/J-NN-<slug>.md` | One journey per file: numbered steps in user language, what the user sees when each step goes wrong, and what they can do next |
| `scope.md` | In / Out / Later as three lists; each constraint marked CONSTRAINT or PREFERENCE with its source; obligatory integrations; sensitive data handled |
| `success.md` | Measurable success criteria: metric, target, where it is observed |
| `scale.md` | Users, transactions, data size, growth, retention |
| `risks.md` | Risk, likelihood, impact, response |
| `docs/specs/glossary.md` | Every domain term used anywhere in the bundle, defined once |

- **Assumptions and open questions are not sections.** They are entries in `docs/discovery/questions.md`,
  cited by id where they apply.
- **Where the project's practices merge files**, `overview.md`, `success.md` and `scale.md` may share
  one file, and the journeys may live in a single `journeys.md` — as long as no file passes 300 lines
  and each still holds one coherent topic.
- **Add every file to the manifest** (`docs/specs/README.md`) as you create it.

## The glossary is not optional

It is the highest-value file for handoff and the one most often dropped. Two words for one concept —
"reservation" and "booking", "agency" and "tenant" — reliably produce two models of it, two sets of
names, and a bug at the seam. Fix the vocabulary here, in the product's own language, and the tech
spec inherits it. Include the terms the users themselves use — in their own language where that
differs — even where they are imprecise, and note the precise meaning this project gives them. The
glossary lives at `docs/specs/glossary.md` and is shared by every phase; past 300 lines, split it by
domain area.

## Done when

- A stranger reading only these files can explain the project, its users and its purpose.
- Every capability maps to at least one journey, and every journey to at least one success criterion.
- Every journey has a stated failure behaviour.
- Scope has an explicit "out" list.
- No technology appears anywhere.
- Every assumption is a register entry rather than prose buried in a paragraph, and no approved file
  cites an unresolved `Q-` entry.
- Every file is within the size budget, opens with its header, and is listed in the manifest.

## Then stop

Present a summary, the `assumed` entries for confirmation, the open questions, and any proposals. Get
approval or corrections before starting the requirements. Do not choose a stack yet — that is the first
decision of the tech spec, and making it here removes the user's choice.
