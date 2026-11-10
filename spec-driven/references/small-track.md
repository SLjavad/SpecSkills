# Small track

**Goal:** a script, a utility or a one-job tool gets one page that says what it is, what it must do
and how it is built — and nothing more. The pipeline is for a product built to last; on a small tool
its weight gets the method abandoned.

For a small-track project this file replaces the phase files — product, requirements, tech spec,
plan, review and changes. `setup.md` still applies for the size, `AGENTS.md` and `CLAUDE.md`; its
operating-mode question, architecture decision, `principles.md` and docs skeleton do not.

## Contents
- When it applies
- The page
- How it runs
- What it leaves out
- What never relaxes
- Outgrowing it

## When it applies

Propose the small track at setup when all of these hold; otherwise the project is standard:

- it is one program that does one job, and its whole description fits one page;
- it is run by its owner or a few people, not offered to users as a product;
- it carries no regulatory, contractual or audit obligation;
- it is not expected to grow into a maintained product.

The user decides, and `AGENTS.md` records it under "Working mode" (`Size: small`). The small track
runs with one agent, so the operating mode is not asked; a project that wants a lead and a coder
takes the standard track. A small but real application — several capabilities, its own data, users
who depend on it — is standard, with the lighter practices `setup.md` offers: merged files and
short ADRs.

## The page

One file, `docs/spec.md`, kept to about a page and never past 150 lines:

```markdown
# <Project>
Status: draft | approved · Updated: YYYY-MM-DD

## What it is
Two to four sentences: what it does, for whom, and why.

## What it must do
1. <one behaviour, in one sentence> — checked by: <the test, or what to run and what to see>

## Out of scope
What it will not do.

## How it is built
The language and runtime with their versions; each library with its reason; where it runs; what it
reads and writes.

## What can go wrong
What happens when an input is bad or something it depends on is down; the secrets and personal data
it handles, and where they live.

## Steps
- [ ] <step> — check: <the command or procedure, and the expected result>

## Assumptions
What the agent decided without asking, for the user to confirm or correct.
```

- **Every item under "What it must do" names its check.** An item nobody can check is a wish.
- **The page holds each choice with its reason**; there are no decision records beside it.
- **No `TBD`.** A point still open is an assumption on the page or a question to the user.
- **Steps are build steps.** The self-review is not one; it is step 4 of "How it runs".
- **`AGENTS.md` holds** the purpose, the commands, a link to the page, the working mode (`single
  agent · Size: small`), the project's own rules and the baseline line for agents with the skills —
  and none of the template's index links, its architecture entry or its line for agents without
  them (senior-engineering `project-knowledge.md`).

## How it runs

1. **Draft the page** from what the user said and what the repository holds. Ask first only what
   blocks the draft — what the tool is, or who it is for; list everything else you decided under
   *Assumptions*. The sweep (senior-engineering "Resolving ambiguity") still runs; that section is
   its record, and no discovery file is written.
2. **One stop.** Present the page with the question for the project's own rules (`setup.md`) and at
   most four others still open — the ones that would change the page most; the rest stay
   assumptions. The user answers, confirms or corrects the assumptions and approves it; the answers
   go into the page, and no code is written before that.
3. **Build it step by step**, in order. Verify each step as it says, then tick it with one line of
   result — what ran and what it showed.
4. **Review your own work before reporting** (senior-engineering `review.md`), security included.
   Fix what you find, and say what you checked and what you could not.
5. **A later change** edits the page and the code together.

## What it leaves out

Requirement ids and the traceability matrix, ADRs, change folders, review files, the question and
proposal registers, the playback file, the indexes and `docs/engineering/`. Questions are asked in
the conversation and their answers written into the page. An idea beyond the page goes into the
report as a proposal, and is built only after the user's yes.

## What never relaxes

Size removes documents and stops, never scrutiny (`setup.md`, "Size is not stakes").
senior-engineering applies in full: ask instead of guessing, test the rules that are hard to get
right, treat security as part of correctness, keep confidential data out of remote tools, and verify
before reporting.

## Outgrowing it

When the list under "When it applies" stops holding — a second job, users who depend on it, data
others rely on — say so and propose the standard track. With the user's yes, run setup as for any
standard project; the page's sections become the first drafts of the product spec, the requirements
and the tech spec, and their phase files apply from then on.
