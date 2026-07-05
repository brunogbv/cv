# Engineering principles

Durable principles for how this repo is built and kept healthy. Unlike the
[constitution](../.specify/memory/constitution.md) — which formalizes the spec-kit / spec-driven
workflow and is in play mainly when running the `/speckit-*` skills — these apply **repo-wide, always,
regardless of tooling**. This document is the canonical home; the constitution and
[`AGENTS.md`](../AGENTS.md) mirror the essentials and point here.

## Guardrails over guidance — prefer executable gates

**Documentation states intent; a gate enforces it.** A documented best practice relies on a fallible
human or agent remembering it at exactly the moment their attention lapses — which is exactly when
mistakes happen. A **deterministic gate** does not: a test, validation, lint rule, hook, or CI check
that mechanically passes or fails cannot be forgotten.

So for a mistake that is **costly or likely to recur** — breaking the PDF, shipping a stale visual
baseline, leaking a secret, regressing accessibility — the durable fix is a gate, not a note. Reach for
one first: **make the wrong thing fail loudly and automatically.**

**Documentation alone is never the final answer to a real, recurring mistake.** When a gate is genuinely
impractical *today*, a documented practice is a stopgap — and it ships *with* a filed
[`harness`](contributing.md#improving-the-harness) issue to add the gate. A best-practice doc with no
gate behind it is a debt, not a solution.

**A near-miss caught only by inspection is the signal that a gate is missing.** If you (or a review)
catch a real, costly problem by eye that no gate would have caught, the catch is not the fix — closing
that gap with a gate is. File it, and treat *that* as the work.

### Why this matters here

This is a tiny static-site repo with **no unit/integration suite** — quality leans on a few automated
gates plus self-review. That makes it *more* important, not less, to convert every recurring or
high-cost failure mode into a gate, so the safety net grows over time instead of relying on vigilance.

### In practice

- The gates we already have: **Super-Linter** (`make lint`), the **visual-regression + PDF-render**
  check (`make visual`), and the **self-review Stop hook** (`.claude/hooks/review-gate.sh`). See
  [CI/CD](ci-cd.md).
- Self-review (constitution Principle II) still backstops everything — this principle is about
  converting the mistakes that recur or bite hard into gates, not about replacing judgment.
- When you find a gap, follow ["Improving the harness"](contributing.md#improving-the-harness):
  propose the gate, and if it can't land now, file a `harness` issue so it's tracked.

> Scope check: this is not "gate every one-off typo." It's "never answer a *costly or recurring*
> mistake with documentation alone." Trivial, unlikely-to-recur mistakes don't need a gate.

## Related

- [Constitution, Principle VII](../.specify/memory/constitution.md) — the spec-kit-era mirror of this
  principle.
- [`AGENTS.md` → "Improving the harness"](../AGENTS.md) — how to apply it when a task surfaces a gap.
- [Contributing → "Improving the harness"](contributing.md#improving-the-harness) — the issue-raising
  process for codifying fixes.
