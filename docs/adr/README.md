# Architecture Decision Records (ADRs)

This folder records significant technical decisions — what we chose, why, the alternatives, and
the trade-offs — so the reasoning survives beyond the PR that made the change.

## When to write one

Write an ADR for a decision that is expensive to reverse, or that a future contributor would look
at and ask "why did we do it this way?" — choosing a library, a runtime, an architecture, or
accepting a notable trade-off.

## Format

Each ADR is a numbered file `NNNN-short-title.md` with:

- **Status** — Proposed / Accepted / Superseded (by ADR-XXXX)
- **Context** — the forces and constraints in play
- **Decision** — what we chose
- **Alternatives considered** — and why they were rejected
- **Consequences** — positive, negative, and follow-ups

Keep them short and durable. Don't rewrite an Accepted decision — instead add a new ADR that
supersedes it and flip the old one's **Status** to `Superseded by ADR-XXXX`.

## Records

- [0001 — Modernize the build runtime: Node 22 + Playwright](0001-modernize-build-runtime.md)
