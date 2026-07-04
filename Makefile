MAKEFLAGS += -s

.PHONY: dev clean page page-container worktree worktree-rm worktree-prune lint lint-actions lint-fast dev-build deploy visual visual-update

# Remove build artifacts
clean:
	echo "Cleaning up..."
	-rm -rf ./dist/ > /dev/null 2>&1

# Open the project in its Dev Container (requires the devcontainer CLI)
dev:
	echo "Starting dev container..."
	devcontainer up --workspace-folder .

# Build the page using local environment
# Dependencies: npm, node
page:
	$(MAKE) clean
	echo "Building page..."
	npm run build

# Build the page inside the Dev Container (no host Node/Playwright needed).
# Preferred way to build/verify locally — the host stays clean.
# Dependencies: devcontainer CLI, Docker
page-container:
	$(MAKE) dev
	devcontainer exec --workspace-folder . make page

# Start a new branch in an isolated git worktree, always off the fresh origin/main
# (avoids branching on a stale local main). Prunes merged worktrees first (best
# effort — never blocks the create). Usage: make worktree name=<branch>
# Dependencies: git (gh optional, for the authoritative merged-PR check)
worktree:
	test -n "$(name)" || { echo "Usage: make worktree name=<branch>  (e.g. make worktree name=fix/typo)"; exit 1; }
	bash scripts/worktree-prune.sh || true
	git fetch origin
	git worktree add "../cv-$(subst /,-,$(name))" -b "$(name)" --no-track origin/main
	echo "Worktree: ../cv-$(subst /,-,$(name))  (branch '$(name)' off origin/main)"
	echo "Next: cd ../cv-$(subst /,-,$(name)) && make page-container   (removed automatically once its PR merges — or now: make worktree-rm name=$(name))"

# Remove a worktree created by `make worktree` plus its per-worktree node_modules volume (the shared
# npm cache is kept). Stop the worktree's Dev Container first, else the volume removal is skipped.
# Usage: make worktree-rm name=<branch>
# Dependencies: git, docker
worktree-rm:
	test -n "$(name)" || { echo "Usage: make worktree-rm name=<branch>  (e.g. make worktree-rm name=fix/typo)"; exit 1; }
	git worktree remove "../cv-$(subst /,-,$(name))"
	docker volume rm "cv-node-modules-cv-$(subst /,-,$(name))" 2>/dev/null && echo "removed node_modules volume" || echo "(node_modules volume not found or in use — stop its Dev Container, then: docker volume rm cv-node-modules-cv-$(subst /,-,$(name)))"
	echo "Removed worktree ../cv-$(subst /,-,$(name))  (shared npm cache kept)"

# Remove all sibling worktrees whose PR has merged, deleting each one's local branch and its
# per-worktree node_modules volume (shared npm cache kept). Safe: skips the main/current worktree,
# the default branch, and any worktree with uncommitted changes. Preview with
# `bash scripts/worktree-prune.sh --dry-run`. Runs automatically before `make worktree`.
# Dependencies: git (gh optional, for the authoritative merged-PR check; docker to drop volumes)
worktree-prune:
	bash scripts/worktree-prune.sh

# Deploy the already-built dist/ to Vercel (Principle I — the deploy command lives in the Makefile).
# CI (.github/workflows/deploy.yml) runs `make page` first, then this. Reads VERCEL_TOKEN /
# VERCEL_ORG_ID / VERCEL_PROJECT_ID from the environment; production when PROD=1 (main), otherwise a
# preview. vercel.json's framework:null + buildCommand:"" make `vercel build` package the existing
# dist/ rather than re-run the Node build. pull/build progress is sent to stderr so stdout is just
# the deployment URL (deploy.yml captures it). The `vercel` CLI is a lockfile-pinned devDependency
# run via `npx` (installed by `npm ci`/`npm install`) — no global install on CI or locally.
# Dependencies: node_modules (run `npm ci`), a built dist/ (run `make page` first)
deploy:
	npx vercel pull --yes --environment=$(if $(PROD),production,preview) >&2
	npx vercel build $(if $(PROD),--prod) >&2
	npx vercel deploy --prebuilt --yes $(if $(PROD),--prod)

# Visual-regression + PDF-render gate (Playwright), run in the SAME pinned Playwright image CI uses,
# so local rendering and the committed baselines match CI exactly (font rendering is the #1 snapshot
# flake). The anonymous `node_modules` volume keeps the container's Linux install from clobbering the
# host's. The image has no `make`, so it calls `npm run build` (what `make page` wraps).
# SOURCE_DATE_EPOCH pins the build's "Last update" date (build.js, which formats it in UTC so the
# calendar day is TZ-independent) so the date baked into the PDF — which the PDF-visual spec
# rasterises and diffs — is stable day-to-day; it matches CI's value in .github/workflows/visual.yml.
# The value (2026-07-03 12:00 UTC → "July 3, 2026") is chosen so the screen render stays
# byte-identical to the committed screen baselines: the "Last update" <time> is hidden in snapshots
# but still occupies layout, so its wrapped height depends on the date string's length (12 chars
# here) — a longer date would reflow it and drift the screen baselines. Dependencies: Docker.
VISUAL_IMAGE := mcr.microsoft.com/playwright:v1.61.1-noble
VISUAL_SOURCE_DATE_EPOCH := 1783080000
visual:
	docker run --rm -e SOURCE_DATE_EPOCH=$(VISUAL_SOURCE_DATE_EPOCH) -v "$(CURDIR):/work" -v /work/node_modules -w /work $(VISUAL_IMAGE) \
		sh -c 'npm ci && npm run build && npx playwright test'

# Refresh the committed snapshot baselines — a reviewed step for intentional visual changes; commit
# the regenerated PNGs (screen breakpoints and PDF pages). Same pinned image + pinned build date so
# baselines match CI. Dependencies: Docker.
visual-update:
	docker run --rm -e SOURCE_DATE_EPOCH=$(VISUAL_SOURCE_DATE_EPOCH) -v "$(CURDIR):/work" -v /work/node_modules -w /work $(VISUAL_IMAGE) \
		sh -c 'npm ci && npm run build && npx playwright test --update-snapshots'

# Full CI-parity lint via the same Super-Linter image CI uses.
#   - Pinned to CI's version (v6.7.0), not `latest`, so a local pass == CI.
#   - `--platform linux/amd64`: Super-Linter ships no arm64 image, so this runs
#     emulated on Apple Silicon (a no-op on amd64 CI/Intel hosts).
#   - Git-dir mount: from a `make worktree` sibling the tree's `.git` is a *file*
#     pointing at the main checkout's `.git` by absolute path, so we also bind-mount
#     that path — otherwise Super-Linter's git can't resolve `main`/`origin/main`. In
#     a plain checkout it's a harmless no-op (the `.git` dir is already in the tree).
#     `safe.directory=*` stops git's "dubious ownership" error on the bind mounts.
#   - `SHELL=/bin/bash`: Super-Linter builds its file list with GNU `parallel`, which
#     runs workers via `$SHELL`; unset, it falls back to `/bin/sh` and can't see the
#     bash functions Super-Linter exports (`BuildFileArrays: not found`). Setting it to
#     bash fixes the file-list step when run locally via `docker run`.
#   - On arm64 the GITHUB_ACTIONS validator (actionlint) crashes with a SIGSEGV under
#     QEMU emulation, so it's skipped here. Super-Linter forbids mixing include (`=true`)
#     and exclude (`=false`) flags, so rather than set it `=false` we lint with a copy of
#     the env-file that drops the `VALIDATE_GITHUB_ACTIONS` line; workflows are checked
#     natively (no emulation) by `make lint-actions` instead.
LINT_IMAGE := ghcr.io/super-linter/super-linter:v6.7.0
LINT_GIT_COMMON_DIR := $(shell git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || echo "$(CURDIR)/.git")
LINT_SKIP_ACTIONS := $(if $(filter arm64 aarch64,$(shell uname -m)),1,)
lint:
	envfile=config/lint/super-linter.env; \
	if [ -n "$(LINT_SKIP_ACTIONS)" ]; then \
		envfile="$$(mktemp)"; trap 'rm -f "$$envfile"' EXIT; \
		grep -v '^VALIDATE_GITHUB_ACTIONS=' config/lint/super-linter.env > "$$envfile"; \
		echo "note: GitHub Actions linting is skipped under emulation on this arch — run 'make lint-actions' to check workflows"; \
	fi; \
	docker run --rm \
		--platform linux/amd64 \
		-e LOG_LEVEL=INFO \
		-e RUN_LOCAL=true \
		-e SHELL=/bin/bash \
		-e GIT_CONFIG_COUNT=1 \
		-e GIT_CONFIG_KEY_0=safe.directory \
		-e GIT_CONFIG_VALUE_0='*' \
		--env-file "$$envfile" \
		-v "$(CURDIR):/tmp/lint" \
		-v "$(LINT_GIT_COMMON_DIR):$(LINT_GIT_COMMON_DIR):ro" \
		$(LINT_IMAGE)

# Lint GitHub Actions workflows with actionlint (native — works on arm64, where the
# emulated Super-Linter above skips its GITHUB_ACTIONS validator). Pinned to the same
# actionlint version Super-Linter v6.7.0 bundles, so this matches the CI check.
lint-actions:
	docker run --rm -v "$(CURDIR):/repo" -w /repo rhysd/actionlint:1.7.1 -color

# Fast local lint (JS via standard, CSS via stylelint, Markdown via markdownlint) — a
# quick subset of `make lint` for the common edit types. `make lint` (Super-Linter)
# stays the authoritative CI-parity check. The stylelint step mirrors Super-Linter's CSS
# ruleset (config/lint/stylelint-fast.json = stylelint-config-standard, same base
# Super-Linter's built-in default uses) over the same file scope Super-Linter lints
# (src/**/*.css + tests/**/*.css; src/templates/** is Handlebars, not CSS). The config is
# NOT named `.stylelintrc.json` on purpose: that filename would make Super-Linter load it
# from the repo, resolving stylelint-config-standard against the repo's newer node_modules
# and tripping the bundled (older) stylelint — like markdownlint-fast.json, it mirrors the
# rules without being picked up by CI.
lint-fast:
	echo "Linting JavaScript (standard)..."
	npx --no-install standard "src/**/*.js"
	echo "Linting CSS (stylelint)..."
	npx --no-install stylelint --config config/lint/stylelint-fast.json "src/**/*.css" "tests/**/*.css"
	echo "Linting Markdown (markdownlint)..."
	npx --no-install markdownlint-cli2 --config config/lint/markdownlint-fast.json "**/*.md" "!node_modules/**" "!.specify/**" "!.claude/skills/**" "!dist/**"

# Build the page in Docker and copy the result into local ./dist — no local Node or
# Playwright needed. Same output as `make page`, self-contained (formerly ran via
# docker-compose; now a standalone build of the root Dockerfile). Dependencies: Docker
dev-build:
	echo "Building the page in Docker (no local Node/Playwright needed)..."
	docker build -t cv-builder .
	-docker rm -f cv-builder-run >/dev/null 2>&1
	docker run --name cv-builder-run cv-builder
	rm -rf ./dist
	docker cp cv-builder-run:/app/dist ./dist
	docker rm -f cv-builder-run >/dev/null 2>&1
	echo "Copied build output into ./dist"
