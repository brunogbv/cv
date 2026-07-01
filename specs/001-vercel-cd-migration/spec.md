# Feature Specification: Migrate hosting & CD to Vercel

**Feature Branch**: `001-vercel-cd-migration`

**Created**: 2026-07-01

**Status**: Draft

**Input**: User description: "Migrate hosting and continuous deployment from the manual GCP VM to
Vercel. The site is a static build (`npm run build` → `dist/` with HTML, assets, and a PDF). Vercel
is already linked to the repo and auto-deploys on push/PR, but every deployment currently fails and
there is no `vercel.json`; real traffic still hits the GCP VM (nginx + manual certbot), where DNS
points. Goals: builds succeed and serve HTML + PDF on every push (production from main, preview per
PR); automatic TLS; retire the manual VM/nginx/certbot stack and its Makefile targets; repoint DNS
for valerio.dev + www to the new platform with a safe, reversible cutover; preserve local dev.
Constraint: builds must be reproducible/self-contained (no reliance on remote CDN fonts at build
time — issue #24). Parity: HTML + a correctly-rendered PDF must remain. Non-goals: changing CV
content, redesigning the page, or switching the templating/build tooling beyond what deployment
requires."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The site builds and serves automatically from the platform (Priority: P1)

The site owner pushes a change; the hosting platform builds the project and serves the resulting
HTML page **and** downloadable PDF at a working URL, with no manual server, build, or certificate
steps. The same mechanism produces an isolated preview for every pull request.

**Why this priority**: This is the foundation of the whole migration. Until a platform build
*succeeds* and serves both artifacts, nothing else (custom domain, VM retirement) can proceed.
Today every deployment fails, so this is the first and most critical slice.

**Independent Test**: Trigger a deployment (push to a branch / open a PR), open the resulting
platform URL, confirm the CV page renders with correct fonts/layout and the PDF is downloadable and
correctly rendered — all without touching a server or issuing a certificate manually.

**Acceptance Scenarios**:

1. **Given** a commit pushed to the default branch, **When** the platform runs its build, **Then**
   the build succeeds and the production URL serves the current HTML page and the PDF.
2. **Given** an open pull request, **When** the platform builds the PR, **Then** a preview URL
   serves the page and PDF, and the deployment status is reported back on the PR.
3. **Given** a build environment with **no access to external font/CSS CDNs**, **When** the build
   runs, **Then** it still succeeds and the PDF is rendered with the correct fonts (no fallback
   fonts, no hang).
4. **Given** a build that fails, **When** the platform processes it, **Then** the previously
   serving production deployment stays live (a broken build is never promoted).

---

### User Story 2 - Visitors reach the real domain on the new platform over HTTPS (Priority: P2)

A visitor navigates to `valerio.dev` (or `www.valerio.dev`) and is served the CV from the new
platform over a valid, automatically-managed HTTPS certificate. The cutover from the old VM is done
via DNS in a way that is verifiable and reversible.

**Why this priority**: This is where real users benefit — production traffic actually moves to the
new platform. It depends on P1 (a working deployment must exist first) and on a DNS change the owner
performs manually.

**Independent Test**: After the cutover runbook is executed, confirm `valerio.dev` and
`www.valerio.dev` resolve to the new platform, load the CV over HTTPS with a valid certificate, and
that a documented rollback restores the VM if needed.

**Acceptance Scenarios**:

1. **Given** the domain has been added to the platform and DNS updated, **When** a visitor loads
   `valerio.dev`, **Then** the CV is served from the new platform over HTTPS with a valid,
   auto-renewing certificate.
2. **Given** the canonical host chosen in FR-007, **When** a visitor loads the other host, **Then**
   they are permanently redirected to the canonical host.
3. **Given** the cutover is in progress, **When** a problem is detected, **Then** the runbook's
   rollback restores serving from the VM (DNS reverted) with no data loss.

---

### User Story 3 - The manual VM/nginx/certbot deploy stack is retired (Priority: P3)

Once the new platform is authoritative and verified in production, the manual deploy machinery
(docker-compose nginx + certbot services, nginx config, and the deploy-oriented Makefile targets) is
removed from the repository and the docs are updated to describe the new push-to-deploy model. The
VM is decommissioned.

**Why this priority**: Pure cleanup/cost-reduction that is only safe *after* P1 and P2 are verified.
It delivers value (no dead code, no VM cost, no confusion) but must come last.

**Independent Test**: Inspect the repo — the manual deploy stack and its Makefile targets are gone,
`docs/ci-cd.md`/`README`/`AGENTS.md` describe the new model, and the VM is powered down with the
site still fully served by the platform.

**Acceptance Scenarios**:

1. **Given** production is verified on the new platform, **When** the retirement change lands,
   **Then** the manual deploy stack and its Makefile targets are removed and the deploy docs reflect
   the platform-based model.
2. **Given** the stack is retired, **When** a contributor looks for how to deploy, **Then** the docs
   point them to the automatic platform deploy (no manual server/cert instructions remain).

---

### Edge Cases

- **Build depends on a third-party CDN that is slow/unreachable at build time** → the build must not
  hang or silently produce a fallback-font PDF; dependencies are self-contained so the outcome is
  deterministic. (Issue #24.)
- **PDF rendering fails in the platform build environment** → the deployment fails loudly (build
  error) rather than promoting a deployment missing or misrendering the PDF.
- **DNS propagation is partial/slow during cutover** → visitors on either resolver path still reach
  a working site; the VM remains live as rollback until propagation is verified.
- **Certificate not yet provisioned right after adding the domain** → cutover waits for a valid
  certificate before DNS is switched (verify-before-switch).
- **A contributor runs a now-removed `make webserver-*` / `make certificates` target** → the target
  no longer exists and docs point to the new model (no partial/old deploy path is silently invoked).
- **`www` vs apex** → both hostnames resolve and serve; the non-canonical one redirects.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every push to the default branch MUST automatically build and deploy the site to
  production, serving both the HTML page and the PDF, with no manual server, build, or certificate
  steps.
- **FR-002**: Every pull request MUST produce an isolated preview deployment reachable via URL, and
  the deployment's success/failure status MUST be reported on the pull request.
- **FR-003**: The deployment build MUST be reproducible and self-contained — it MUST NOT depend on
  the availability of third-party CDNs (fonts/CSS) at build time. (Addresses issue #24.)
- **FR-004**: The deployed site MUST include both the HTML page and a correctly-rendered,
  consistently-fonted PDF, at parity with the pre-migration output.
- **FR-005**: The PDF MUST remain available at its existing download URL — same path **and**
  filename — so external links do not break.
- **FR-006**: HTTPS certificates for the production domain MUST be provisioned and renewed
  automatically by the platform, with no manual certificate issuance or renewal.
- **FR-007**: After cutover, `valerio.dev` and `www.valerio.dev` MUST serve the site from the new
  platform. The canonical host and redirect direction is [NEEDS CLARIFICATION: canonical domain not
  decided — apex `valerio.dev` with `www` redirecting to it, or the reverse?].
- **FR-008**: A failed build MUST NOT replace the currently-serving production deployment (last good
  deployment stays live).
- **FR-009**: The DNS cutover MUST follow a documented runbook that (a) lowers record TTL
  beforehand, (b) verifies platform serving and a valid certificate before switching, and (c)
  preserves a rollback to the VM until the new platform is verified. DNS record changes are executed
  manually by the site owner at the DNS provider and are outside the repository.
- **FR-010**: The manual VM/nginx/certbot deploy stack and its deploy-oriented Makefile targets MUST
  be removed once the platform is authoritative, and the deploy documentation updated accordingly.
  The timing/scope is [NEEDS CLARIFICATION: is stack retirement + VM decommission part of THIS
  initiative (as its final phase, after cutover is verified) or a separate follow-up?].
- **FR-011**: Local development (build, live preview, and lint) MUST remain functional and
  unchanged by the migration.
- **FR-012**: The cutover MUST retain a working rollback to the VM for
  [NEEDS CLARIFICATION: rollback retention window not specified — how long should the VM stay live
  and DNS-reversible after cutover before it is decommissioned?].
- **FR-013**: Content caching MUST NOT prevent a new successful deployment from becoming visible
  promptly, nor prevent a DNS rollback from restoring the previous source within the cutover
  verification window (no stale-cache lock-in during cutover).

### Key Entities

- **Deployment environments**: *Production* (served from the default branch) and *Preview* (one per
  pull request) — each a fully built, independently reachable instance of the site.
- **Served artifacts**: the HTML CV page and the downloadable PDF; both must be present and at
  parity for a deployment to be considered valid.
- **Production domain**: `valerio.dev` and `www.valerio.dev`, with one canonical host and the other
  redirecting; TLS is platform-managed.
- **Cutover runbook**: the owner-executed sequence (lower TTL → add domain on platform → verify
  serving + certificate → switch DNS → verify → keep VM as rollback → decommission).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of pushes to the default branch result in an automatically deployed, publicly
  reachable production site (HTML + PDF) with zero manual server or certificate steps.
- **SC-002**: Every pull request receives a working preview URL (page + PDF render correctly) with
  its deployment status shown on the PR.
- **SC-003**: The build succeeds and produces a correctly-fonted PDF with **no** access to external
  font/CSS CDNs at build time (verified by building with external CDN access blocked).
- **SC-004**: The production domain (`valerio.dev` and `www.valerio.dev`) loads over HTTPS with a
  valid, automatically-renewing certificate, requiring **zero** manual certificate renewals.
- **SC-005**: The DNS cutover completes with continuous availability — external uptime probes record
  zero failed requests across the cutover window — and a rehearsed rollback can restore VM serving.
- **SC-006**: Shipping a content change requires **zero** manual deploy steps after migration
  (versus the current multi-step manual VM + certbot process).
- **SC-007**: The migrated HTML page and PDF match a baseline captured immediately before cutover
  (same fonts, layout, and content, confirmed by side-by-side comparison) — no visual or content
  regression.

## Assumptions

- The target platform is **Vercel**, already linked to the GitHub repo (project
  `bruno-valerios-projects/cv`); this initiative makes its builds succeed and cuts traffic over to
  it, rather than introducing a new integration from scratch.
- Issue **#24** (vendoring fonts/CSS so the build is self-contained) is **in scope** and is a
  prerequisite for User Story 1 (P1): reliable platform builds depend on it.
- Production deploys from the default branch (`main`) and previews from pull requests, matching the
  platform's standard git-driven model.
- **DNS changes are performed manually by the site owner** at their DNS provider; the repository and
  automated tooling cannot modify DNS. Record TTL is lowered ahead of the cutover.
- Near-zero downtime is expected; the cutover is DNS-based with the VM kept live as a rollback until
  the platform is verified in production.
- Any historical GitHub Pages deployment is considered superseded and out of active use; it is not
  part of the retirement scope unless found to still serve traffic.
- Feature parity is required: the HTML page and a correctly-rendered PDF remain available, with the
  PDF at its current path.
- The *how* of producing the PDF within the platform build (e.g., headless-browser rendering in the
  build vs. an alternative) is an implementation decision deferred to `/speckit-plan`, not this spec.
