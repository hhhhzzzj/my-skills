---
name: "tutorial-writer"
description: "Write PocketFlow-style codebase tutorials. Multi-chapter markdown that reads like a book — each chapter opens with a metaphor, narrates a core abstraction, anchors to real file:line references, and reflects on design trade-offs. Trigger for: 'write a tutorial for this project', 'PocketFlow style', 'turn this repo into a book', 'deep walkthrough', '深入讲讲这个项目'. Do NOT use for single-page onboarding docs (use codebase-onboarding) or VS Code .tour files (use code-tour)."
---

# Tutorial Writer

Inspired by [PocketFlow tutorial-codebase-knowledge](https://github.com/The-Pocket/PocketFlow-Tutorial-Codebase-Knowledge). Turn a codebase into a **multi-chapter tutorial** — narrative, metaphor-driven, anchored in real code.

## When to use

**Trigger on**:

- "Write a tutorial for this project"
- "PocketFlow style"
- "Turn this repo into a book"
- "Deep walkthrough"
- "深入讲讲这个项目" / "把这仓库当本书写"

**Do NOT use for**:

- Single-page onboarding doc → use `codebase-onboarding`
- VS Code `.tour` file (step-by-step walkthrough with file:line anchors) → use `code-tour`
- Code quality / tech debt assessment → use `tech-debt-tracker`

## Output structure

```
tutorial/
├── index.md              # Table of contents + reading order + time estimate
├── 00-introduction.md    # Project framing + metaphor + system map
├── 01-<concept>.md       # Core abstraction 1
├── 02-<concept>.md       # Core abstraction 2
├── ...
└── 0N-conclusion.md      # Recap + what to do next
```

**5–9 chapters is the sweet spot.** Fewer than 5 = nothing learned in depth. More than 9 = chapter fragmentation; consolidate.

## Workflow

### Step 1 — Explore the repo (≤ 10 min)

Read: README, top-level directories, entry-point files (`main.*`, `index.*`, `app.*`), main dependency manifest.

Record mentally:
- One-line project identity
- Main tech stack
- Entry points (where input enters the system)
- External I/O surface (APIs / CLI / library exports)

### Step 2 — Identify 5–9 core abstractions

A **core abstraction** is a concept the reader *must* understand to make sense of the project. It can be:

- A central class or struct (e.g. `Agent`, `Pipeline`, `Store`)
- A data-flow pattern (e.g. "event subscription", "request-response loop")
- An integration boundary (e.g. "external API adapter layer")

**Selection criteria**:

| Pick if | Skip if |
|---|---|
| It is **specific to this project's intelligence** | It is generic framework behavior (don't re-explain React) |
| The reader **cannot avoid** encountering it | It is a leaf utility used once |
| It **interacts** with other abstractions | It is fully self-contained |

### Step 3 — Order the narrative

Order by **what the reader most wants to know next**, not by complexity:

1. **Entry** — where does input enter?
2. **Core data** — what objects flow through the system?
3. **Core mechanism** — the project's distinctive algorithm or pattern
4. **Periphery** — plugins, external integrations, advanced features

Resist the urge to go simple-to-complex. Readers want the heart of the system early, then context.

### Step 4 — Write each chapter using the SCAR formula

**Every chapter has four sections** (use these as section names or as a mental check):

| Section | Purpose |
|---|---|
| **S — Setup** | What problem does this chapter solve? What did the reader see before getting here? |
| **C — Concept** | Lead with a **metaphor** or **analogy**. Then the noun definition. |
| **A — Action** | Look at actual code: `@path/to/file.ext:line-range`, 10–30 lines that capture the abstraction's heartbeat. Explain what it does. |
| **R — Reflection** | Why this design? What's the trade-off? What would happen if you replaced it with X? |

**Chapter length**: 800–2000 words. Important abstractions warrant more, simple ones less. Resist averaging.

#### Choosing the metaphor

- **Everyday**: post office, restaurant kitchen, assembly line, library checkout
- **Tool-analogy**: "like X library's Y pattern but with Z difference"
- **Always state the metaphor's edges**: what is similar, what is *not* — to prevent misleading the reader

Example:

> The Agent pattern works like a **triage nurse in an emergency room**: a patient (request) arrives and the nurse decides which department should handle it (which tool to call), routing the case rather than treating it directly. Unlike a real nurse, though, the Agent loops — its next question depends on the previous answer, so it can have a multi-turn conversation with the system.

### Step 5 — Write index.md and 00-introduction.md last

After all content chapters are drafted, write the bookends:

**index.md**:
- One-line project identity
- Chapter list with one sentence per chapter
- Estimated reading time (rough: 800 words ≈ 4 min)
- Recommended reading order (may differ from numbering — flag if so)

**00-introduction.md**:
- **Open with the metaphor** (NOT "This project is a ...")
- Concrete I/O example (what goes in, what comes out — show literal data)
- System map: a Mermaid diagram with 3–7 nodes covering the abstractions you'll explain
- Who should read this tutorial (and who can skip)

## Quality bar

| Not allowed | Allowed |
|---|---|
| "This project is an X-based Y system" | "This project works like X does Y — but with Z difference" |
| Paraphrasing the README | Insight the README does NOT contain |
| Listing every file | Citing only files that illuminate an abstraction |
| Equal depth for every chapter | Important = thick, simple = 1–2 paragraphs |
| Stating inference as fact | Mark as "my reading" or "appears to" when unsure |

## Anti-patterns

- ❌ **Textbook voice**: "In this chapter we will learn..."
- ❌ **Directory transcription**: chapter 1 = `src/api/`, chapter 2 = `src/db/`...
- ❌ **Zero metaphors**: a tutorial without analogies is a reference manual
- ❌ **Code-free chapters**: abstractions need anchored examples
- ❌ **Egalitarianism**: all 5 abstractions get exactly 1500 words
- ❌ **Recap closings**: "we learned X, Y, Z" — instead say what the reader can now *do*

## Cross-references

- `codebase-onboarding` — single-page onboarding doc (when reader is in a hurry)
- `code-tour` — VS Code `.tour` step-by-step walkthrough (when reader wants to click through in IDE)
- Inspiration: [PocketFlow tutorial-codebase-knowledge](https://github.com/The-Pocket/PocketFlow-Tutorial-Codebase-Knowledge)
