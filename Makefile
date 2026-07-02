MAKEFLAGS += -s

.PHONY: dev clean page page-container worktree worktree-rm worktree-prune lint lint-actions lint-fast build dev-build deploy \
	logs-app-builder logs-webserver logs-certbot \
	remove-app-builder remove-certbot \
	certificates certificates-dry-run \
	webserver-ssl-config webserver-restart-nginx webserver-upgrade-to-https \
	down webserver-local webserver all

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
# the deployment URL (deploy.yml captures it). Needs the `vercel` CLI on PATH (CI: npm i -g vercel).
# Dependencies: vercel CLI, a built dist/ (run `make page` first)
deploy:
	vercel pull --yes --environment=$(if $(PROD),production,preview) >&2
	vercel build $(if $(PROD),--prod) >&2
	vercel deploy --prebuilt --yes $(if $(PROD),--prod)

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

# Fast local lint (JS via standard, Markdown via markdownlint) — a quick subset of
# `make lint` for the common edit types. `make lint` (Super-Linter) stays the
# authoritative CI-parity check.
lint-fast:
	echo "Linting JavaScript (standard)..."
	npx --no-install standard "src/**/*.js"
	echo "Linting Markdown (markdownlint)..."
	npx --no-install markdownlint-cli2 --config config/lint/markdownlint-fast.json "**/*.md" "!node_modules/**" "!.specify/**" "!.claude/skills/**" "!dist/**"

# Build the page using dockerized environment
# Useful for deploying the page to a server when certificates are already created
# output will be stored in the container's /app/dist folder and mounted to shared volume cv_dist
build:
	echo "Building page..."
	$(MAKE) remove-app-builder
	docker compose up --build app-builder

# Build the page using dockerized environment and copy files to local dist folder
# Useful for building the page without having to install dependencies on local machine
# Same as make page, but no dependency requirements on local machine
dev-build:
	echo "Building page..."
	$(MAKE) remove-app-builder
	$(MAKE) build
	docker cp app-builder:/app/dist ./dist

# Get the logs of the app-builder, useful for debugging build issues
logs-app-builder:
	docker compose logs -f app-builder

# Get the logs of the webserver, useful for debugging nginx issues
logs-webserver:
	docker compose logs -f webserver

# Get the logs of the certbot, useful for debugging issues when creating certificates
logs-certbot:
	docker compose logs -f certbot

# Useful if you need to remove the app-builder container
remove-app-builder:
	echo "Removing build container..."
	-docker rm -f app-builder > /dev/null 2>&1

# Useful if you need to remove the certbot container
remove-certbot:
	echo "Removing certbot..."
	-docker rm -f certbot > /dev/null 2>&1
	-docker rm -f certbot-dry-run > /dev/null 2>&1

# Create certificates using dockerized certbot
# certs are stored in ./certbot/conf/live/valerio.dev/ and mounted to shared volume cv_certs
certificates:
	echo "Creating certificates..."
	docker compose up certbot
	$(MAKE) remove-certbot

# Create certificates using dockerized certbot
# certs are stored in ./certbot/conf/live/valerio.dev/ and mounted to shared volume cv_certs
certificates-dry-run:
	echo "Creating certificates (dry run)..."
	docker compose up certbot-dry-run
	$(MAKE) remove-certbot

# Updates the nginx configuration to use the newly created certificates
# Enables SSL and redirects all HTTP traffic to HTTPS
webserver-ssl-config:
	echo "Creating SSL configuration..."
	docker exec webserver cp /etc/nginx/sites-available/valerio-ssl.conf /etc/nginx/sites-available/valerio.dev

# Restarts the nginx server to apply new configurations
webserver-restart-nginx:
	echo "Restarting nginx..."
	docker exec webserver nginx -s reload

# Upgrades the webserver to use HTTPS
# This is the main command to run to enable HTTPS on the webserver
webserver-upgrade-to-https:
	$(MAKE) certificates
	$(MAKE) webserver-ssl-config
	$(MAKE) webserver-restart-nginx

# Downs the webserver
down:
	echo "Downing webserver..."
	docker compose down

# Adds localhost to nginx server_name
# Useful for local development
webserver-local:
	echo "Hosting nginx..."
	docker buildx build --build-arg SITE_NAME=valerio-local.conf -t valerio.dev:local
	docker compose up -d webserver

# Starts the webserver
webserver:
	echo "Hosting nginx..."
	docker compose up -d --build webserver

# Full build and deploy
# Useful for deploying the page to a server for the first time
# Avoid running this command if you are just updating the page as it will recreate the certificates
all:
	$(MAKE) build
	$(MAKE) webserver
	$(MAKE) webserver-upgrade-to-https
