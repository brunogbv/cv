MAKEFLAGS += -s

.PHONY: dev clean page page-container worktree worktree-rm lint lint-fast build dev-build \
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
# (avoids branching on a stale local main). Usage: make worktree name=<branch>
# Dependencies: git
worktree:
	test -n "$(name)" || { echo "Usage: make worktree name=<branch>  (e.g. make worktree name=fix/typo)"; exit 1; }
	git fetch origin
	git worktree add "../cv-$(subst /,-,$(name))" -b "$(name)" --no-track origin/main
	echo "Worktree: ../cv-$(subst /,-,$(name))  (branch '$(name)' off origin/main)"
	echo "Next: cd ../cv-$(subst /,-,$(name)) && make page-container   (remove later: make worktree-rm name=$(name))"

# Remove a worktree created by `make worktree` plus its per-worktree node_modules volume (the shared
# npm cache is kept). Stop the worktree's Dev Container first, else the volume removal is skipped.
# Usage: make worktree-rm name=<branch>
# Dependencies: git, docker
worktree-rm:
	test -n "$(name)" || { echo "Usage: make worktree-rm name=<branch>  (e.g. make worktree-rm name=fix/typo)"; exit 1; }
	git worktree remove "../cv-$(subst /,-,$(name))"
	docker volume rm "cv-node-modules-cv-$(subst /,-,$(name))" 2>/dev/null && echo "removed node_modules volume" || echo "(node_modules volume not found or in use — stop its Dev Container, then: docker volume rm cv-node-modules-cv-$(subst /,-,$(name)))"
	echo "Removed worktree ../cv-$(subst /,-,$(name))  (shared npm cache kept)"

lint:
	docker run --rm \
		-e LOG_LEVEL=INFO \
		-e RUN_LOCAL=true \
		--env-file "config/lint/super-linter.env" \
		-v $(shell pwd):/tmp/lint \
		ghcr.io/super-linter/super-linter:latest

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
