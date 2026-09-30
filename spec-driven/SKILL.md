---
name: spec-driven
description: Run a project spec-first - define the product (problem, users, value, services, goal), then a technical spec detailed enough to build from (stack, architecture, domain and data model, contracts, components, flows, algorithms), then a stepwise implementation plan, then review with recorded feedback. The spec bundle is a self-contained handoff artifact any agent or model can implement from. Use when starting a new project or major feature, writing a product or technical spec, planning an implementation, handing work to another agent, or reviewing an implementation against its spec.
---

# Spec-driven development

Build the understanding before the code. The output of the spec phases is a **cook book**: a bundle
of documents complete enough that a different agent, on a different model, with none of the
conversation that produced them, can implement the project correctly.

That constraint is what makes this method worth the effort, and it is the bar every document is held
to.

## The pipeline

```
1. Product spec   what and why             → docs/specs/01-product-spec.md
2. Requirements   what exactly, how well   → docs/specs/02-requirements.md
3. Tech spec      how                      → docs/specs/03-tech-spec.md
4. Plan           in what order             → docs/specs/04-implementation-plan.md
   ─────────────── handoff gate ───────────────
5. Implementation  (optional, may be a different agent)
6. Review          → docs/specs/reviews/NNN-review.md   ⇄ back to 5
```

**Phases 1-4 run to completion before any implementation code is written.** When the plan is done,
stop and hand the bundle back. The user decides whether to implement here, later, or elsewhere.

## Load the phase you are in

Read the reference file for the current phase, not all of them:

| Phase | File |
|---|---|
| Product spec | `references/product-spec.md` |
| Requirements | `references/requirements.md` |
| Tech spec | `references/tech-spec.md` |
| Plan | `references/plan.md` |
| Implementation | the plan itself, plus `senior-engineering` for how to build |
| Review | `references/review.md` |

`senior-engineering` is the always-on baseline for engineering judgement and applies throughout.
Use the project's own refactoring or cleanup skill when one exists.

## The handoff contract

Every document in the bundle must satisfy all of these. A document that fails any of them is not
finished, however long it is.

- **Self-contained.** No "as we discussed", "the approach above", "the usual pattern", or reference
  to anything outside the bundle. Cross-references are by document and section number.
- **No pronouns pointing at the conversation.** The reader was not there.
- **Every decision carries its reason.** A decision without a rationale gets silently reversed by the
  next reader who prefers something else.
- **No `TBD`, no `etc.`, no "to be determined during implementation".** Either decide it, or record it
  under Open Questions marked **escalate, do not guess** — naming who decides and what the options
  are. An implementer must never have to invent a requirement.
- **Concrete over descriptive.** Not "store the amount" but the field, its type, its precision, its
  nullability, and its unit. Not "handle errors" but which error, what the caller sees, what is
  logged, what is stored.
- **Terms are defined once, in the glossary, and used consistently.** Two words for one concept is how
  two implementations of it get built.
- **Everything downstream of phase 2 cites requirement ids.** Components, flows, plan steps and review
  findings name the `FR-`/`NFR-` they serve, and the traceability matrix in the requirements document
  is the one place coverage is recorded. An implementer should never have to guess which requirement a
  piece of work exists for.

Before declaring a phase done, run this test: *if I handed only this bundle to a competent stranger,
what would they have to ask me?* Every answer is a gap. Fix it or record it as an open question.

## Working method for the spec phases

**Draft, then challenge.** Do not interrogate the user from a blank page, and do not invent
requirements to fill silence. Write a first pass from what you have been told, marking every
inference you made, then come back with targeted questions on the gaps that actually matter.

**Ask when two readings lead to materially different work.** Specs are where questions are cheapest —
a wrong assumption here costs a paragraph, the same assumption in code costs a rewrite. Decide the
routine things yourself and say that you did.

**Batch questions.** Do the whole draft, collect what is genuinely unresolved, ask once with real
options and trade-offs. A question per paragraph is exhausting and trains the user to stop reading.

**Separate what you know from what you assumed.** Every document has an Assumptions section, and
anything in it is a thing the user can correct cheaply.

**Write no implementation code during phases 1-4.** Sketching a type signature or a schema fragment
inside the tech spec is the spec; creating project files is not. Research is the exception: if you need
to check a library's behaviour, or measure a baseline to put a real number on an NFR, build a
throwaway probe in a scratch directory, keep the number, and say that is what you did.

## Order matters, and so does separation

- **The product spec contains no technology.** No framework, no database, no library. If a sentence
  names one, it belongs in the tech spec. This is what keeps the product decisions from being quietly
  driven by an implementation preference.
- **The requirements contain no solution language either**, and no requirement without a source in the
  product spec. They are that document made countable and checkable, not a second draft of it.
- **The tech spec contains no product decisions and no new requirements.** If writing it surfaces a
  product question — what should happen when two users claim the same slot — that goes back to phase 1
  and forward through phase 2. If it surfaces a missing requirement, add it in phase 2 rather than
  burying it in a design paragraph.
- **The plan contains no new decisions at all.** It is an ordering of work already specified. If a
  step needs a decision, the tech spec is incomplete; fix it there.

Each phase may send you back to an earlier one. That is the method working, not a failure — the cost
of going back one document is trivial compared with discovering it during implementation.

## Gates

**After each of phases 1 to 4: stop and present.** Summarize what the document decides, list
every assumption, list every open question, and ask for approval or corrections. Do not roll straight
into the next phase.

**After phase 4: hand off.** State that the bundle is complete, where the four files are, and what an
implementing agent should read first. Do not begin implementing unless the user asks you to.

**During implementation (phase 5):** work the plan step by step, in order. After each step, verify it
as the plan specifies, record the result, and fill in that step's row in the traceability matrix. Do
not batch several steps and verify at the end, and do not improvise work that is not in the plan — if
the plan is wrong, say so and amend it.

**Review (phase 6)** may be run by any agent the user chooses — the spec author, the implementer, or
a fresh one. Write it so it works for a reviewer with no context: it reads the bundle and the code.
Findings are recorded to a file, not just reported in chat, so the loop survives a new session.

## Amending an approved spec

Specs drift. When implementation reveals the spec is wrong, that is a **finding against the spec**,
not a licence to diverge.

1. Stop and say what the spec got wrong.
2. Amend the document, keeping the superseded decision visible with the reason it changed. Do not
   quietly overwrite history — the rejected reason is what stops it being re-proposed.
3. Then continue.

Code that silently disagrees with an approved spec is the worst outcome of this method, because the
document is now actively misleading — worse than having no document.

## Anti-patterns

| Symptom | What it means |
|---|---|
| Spec full of `TBD` | Decisions deferred to whoever is least equipped to make them |
| Tech spec naming no versions | "Latest" is not reproducible |
| Flow with only a happy path | The failure behaviour will be invented under pressure |
| Plan step verified by "it builds" | Not a verification |
| Plan step that touches "wherever needed" | The component inventory is incomplete |
| Product spec naming a database | Solution chosen before the problem was stated |
| A step whose result is checked three steps later | Wrong step boundaries |
| Findings reported only in chat | Lost at the end of the session |
| "The implementer can decide" | Either specify it or mark it escalate-do-not-guess |
| NFR with no number | A wish; it will be declared met by whoever is asked |
| A `Must` requirement with no plan step | Unimplemented, and invisible without the matrix |
| Requirement with no product-spec source | Invented scope, or an incomplete product spec |
| An NFR category left silent | Not "not applicable" — just undiscovered until production |
| "Verified" on an NFR whose mechanism was checked but outcome was not | Two different claims |
