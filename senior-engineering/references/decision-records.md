# Decision records

Code shows what; it does not show which alternatives were tried and why they failed. Decisions are
recorded where the next reader — human or agent, in any tool — will find them. This is the mechanism
that lets the next session start informed instead of from zero, and it is worth more than any amount
of in-code documentation.

## Contents
- Three kinds of record
- When a decision needs an ADR
- The ADR template
- Lifecycle rules
- Area records and scoped rules
- Code that looks wrong and is not

## Three kinds of record

| Record | Holds | Changes |
|---|---|---|
| ADR — `docs/adr/NNNN-<slug>.md` | One significant decision: its context, the options, the choice, the consequences | Never rewritten once decided; superseded by a new ADR |
| Area record — `docs/engineering/areas/<area>.md` | What an area does *now*, why it is that way, what not to undo, and the ADRs that govern it | Kept current; delete what a change made false |
| Implementation note — in a plan step or a report | A small choice inside the approved spec, with its reason | Lives with the work |

If the repository already keeps decisions elsewhere (`docs/decisions/`, `doc/adr/`), follow it.

## When a decision needs an ADR

Write one when the decision:
- shapes the structure — a module boundary, an interface or a schema others will build on;
- chooses or drops a significant dependency, framework, datastore, protocol or hosting model;
- is how an architecturally significant quality requirement will be met;
- sets a construction technique or a cross-cutting convention — the error model, the auth model, the
  id strategy;
- is expensive to reverse, a first of its kind here, or in an area where the project had trouble
  before.

Skip it for local, cheap-to-reverse choices inside one component; those are implementation notes.
Propose backfilling an ADR when you discover an undocumented decision that matters.

## The ADR template

Plain Markdown, in two sizes of one shape. **The short form** fits most decisions in 20–40 lines. **The
full form** adds the sections after it, for a decision that is expensive to reverse, architecturally
significant, or in an area where the project had trouble before — unless the project's practices chose
the short form. Neither passes about 150 lines. Once a decision is accepted, a confirmation or rule
added later goes in a dated addendum.

```markdown
# ADR-NNNN: <the decision, as a short phrase>
Status: proposed | accepted | rejected | deprecated | superseded by ADR-NNNN
Date: YYYY-MM-DD · Proposed by: <agent/role or person> · Decided by: <the user>, YYYY-MM-DD
Confidence: high | medium | low · Scope: <modules; optional path globs>
Relates to: <FR-/NFR- ids, Q-, P-, spec files> · Supersedes: <ADR-NNNN or none>
Summary: <one line: what was decided>

## Context and problem
What forces a decision now, in two to five sentences — with the requirement ids that drive it, and the
sources, if research informed it.

## Considered options
At least two real options; doing nothing may be one of them.

## Decision
"We will …" — then one line: in the context of <X>, facing <Y>, we decided for <Z> and against <W>,
to achieve <Q>, accepting <D>.

## Consequences
Good, bad and neutral: what this now forces or forbids.
```

The full form adds, after the consequences:

```markdown
## Decision drivers
The requirement ids and constraints that decide it, one per line.

## Confirmation
How compliance is checked — an architecture test, a review checklist item, a metric.

## Rules for implementers
Short MUST / MUST NOT lines an implementer can follow without reading the rest.

## Pros and cons of the options

## Sources
| Source | What it contributed | Checked |
|---|---|---|

## Revisit when
The condition that would reopen this decision.
```

## Lifecycle rules

- **Agents propose; the user decides.** An agent writes an ADR as `proposed`. Only the user moves it to
  `accepted` or `rejected`, and the record says who decided and when. `deprecated` means it no longer
  applies and nothing replaces it; `superseded` means a newer ADR does.
- **Edit freely while it is proposed. Once decided, never rewrite it** — change only the status and the
  links, or add a dated addendum. A new decision is a new ADR that supersedes the old one, and the old
  one is marked `superseded by`. The rejected reasoning is what stops the same debate recurring.
- **One decision per ADR.** Numbers are sequential and never reused; one writer allocates them — the
  lead agent, in a multi-agent project — so parallel work cannot collide.
- **Index**: `docs/adr/README.md` lists every ADR with its number, title, status and date.
- **Reference, never copy.** A tech spec states the choice in one line and links the ADR; the
  rationale lives only in the ADR.

## Area records and scoped rules

An area record is the current-state memory of one area. The highest-value content in it is what you
decided *not* to do, and why — it stops the next reader "fixing" something deliberate.

- **Record the reason, not just the rule.** "Do not convert either side of that comparison" is
  unactionable without the paragraph explaining what the comparison is for.
- **List the accepted ADRs that govern the area**, and relink when one is superseded.
- **Delete what a change made false** rather than rewriting around it.

**Make the rules arrive with the code.** Most agent tools read an `AGENTS.md` in the directory being
worked on. For an area that maps to a directory, put a short `AGENTS.md` there — the rules, each citing
its ADR, plus a link to the area record — and, for Claude Code, a sibling `CLAUDE.md` whose only line
is `@AGENTS.md`: under Claude Code's default settings, a project with a root `CLAUDE.md` does not read
nested `AGENTS.md` files by itself. In a Claude-only project, a `.claude/rules/<area>.md` file with
`paths:` frontmatter does the same job by glob. Keep these files short, and write them only from
accepted ADRs.

## Code that looks wrong and is not

Every mature codebase contains deliberate oddities written that way because the obvious version was
tried and broke something. Treat unfamiliar-looking code as load-bearing until you have read the
reason.

- **Before "fixing" anything that looks clumsy, look for its rationale** in the area record, the ADRs
  and the project instructions. If it is explained, it is not a target.
- **If you believe it is genuinely wrong, say so and propose it separately** — never fold it into
  unrelated work.
- **When you discover why something odd is necessary, write it into the area record**, with the failure
  it prevents. That entry is worth more than the fix that prompted it.
- **Performance-shaped and framework-shaped oddities are the usual kind**: a query written the long way
  because the tidy form makes the ORM emit something pathological, a declaration order that is
  actually filter nesting, an escaping option that keeps non-Latin text readable. None of these look
  like anything from the outside.

Maintain that list per project. It is the cheapest defence against a confident agent — including
you — undoing a hard-won fix.
