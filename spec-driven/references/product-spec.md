# Phase 1 — Product spec

**Goal:** a reader who knows nothing about this project can say what it is, who it serves, what
problem it removes, and how you will know it worked.

**Hard rule: no technology in this document.** No framework, language, database, library, hosting or
protocol. If a sentence names one, move it to the tech spec. A product spec that has already chosen
a database has skipped the thinking this phase exists for.

Write to `docs/specs/01-product-spec.md`.

## What to establish

Work through these. Draft an answer for each from what you have been told, mark what you inferred,
then ask about the gaps that would change the work.

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

- In scope, out of scope, and explicitly later. The "out" list is what prevents scope creep, so it
  must be written down even when it feels obvious.
- What must this integrate with, and is that an obligation or a preference?
- What are the real constraints — legal, regulatory, contractual, deadline, budget, existing systems?
  Mark each as constraint or preference; a preference can be traded, a constraint cannot.

**Reality checks**

- How is success measured, with what number, observed where? "Users are happier" is not measurable.
- What has to be true for this to work that is not under your control?
- What is the biggest risk, and what would you do if it happened?
- Volume and scale expectations, in the user's terms: how many users, how many transactions, how
  much data, growing how fast. The tech spec cannot be sized without this.

## Document template

```markdown
# <Project> — Product Specification
Status: draft | approved   Version: n   Date: YYYY-MM-DD

## 1. Summary
One paragraph: what this is, who it is for, why it exists.

## 2. Problem
The situation today and what it costs. Evidence where available.

## 3. Value and goal
What changes, for whom. The single primary success outcome.

## 4. Users and roles
Per role: name, what they are trying to do, primary or secondary.

## 5. Capabilities
Per capability: name, one-line description, which role, frequency,
impact if unavailable.

## 6. Journeys
Primary journey as numbered steps in user language, then secondary
journeys. Each with its failure behaviour: what the user sees, what
they can do next.

## 7. Scope
In / Out / Later, as three explicit lists.

## 8. Success criteria
Measurable statements: metric, target, where observed.

## 9. Constraints
Each marked CONSTRAINT or PREFERENCE, with its source.

## 10. Volume and scale
Users, transactions, data size, growth, retention expectations.

## 11. Assumptions
Everything taken as true without confirmation. Each one correctable.

## 12. Open questions
Unresolved items. Each marked either RESOLVE BEFORE TECH SPEC or
ESCALATE — DO NOT GUESS, naming who decides and the options.

## 13. Risks
Risk, likelihood, impact, response.

## 14. Glossary
Every domain term used anywhere in the bundle, defined once. Include
the terms the users themselves use, even where they are imprecise,
and note the precise meaning this project gives them.
```

## The glossary is not optional

It is the highest-value section for handoff and the one most often dropped. Two words for one
concept — "reservation" and "booking", "agency" and "tenant" — reliably produce two models of it, two
sets of names, and a bug at the seam. Fix the vocabulary here, in the product's own language, and the
tech spec inherits it.

## Done when

- A stranger reading only this document can explain the project, its users and its purpose.
- Every capability maps to at least one journey, and every journey to at least one success criterion.
- Every journey has a stated failure behaviour.
- Scope has an explicit "out" list.
- No technology appears anywhere.
- Every assumption is listed rather than embedded in prose.
- No `TBD`.

## Then stop

Present a summary, the assumptions, and the open questions. Get approval or corrections before
starting the tech spec. Do not choose a stack yet — that is the first decision of phase 2, and making
it here removes the user's choice.
