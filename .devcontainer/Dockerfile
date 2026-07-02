# Dev Container image for the CV repo.
#
# Bakes the heavy, workspace-INDEPENDENT tooling into the image so it persists across container
# rebuilds and is cheap per git worktree. Workspace-specific dependencies (node_modules) stay in
# postCreate. See docs/local-development.md.
FROM mcr.microsoft.com/devcontainers/javascript-node:22-bookworm

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The Dev Container runs as root by design (devcontainer.json sets remoteUser: root), and the build
# steps below need root (apt via playwright --with-deps, global npm/uv installs).
# hadolint ignore=DL3002
USER root

# uv + the spec-kit `specify` CLI (workspace-independent). uv's standalone installer needs no Python.
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh \
  && UV_TOOL_BIN_DIR=/usr/local/bin uv tool install \
    --from git+https://github.com/github/spec-kit.git specify-cli

# Claude Code CLI (workspace-independent global).
# hadolint ignore=DL3016
RUN npm install -g @anthropic-ai/claude-code

# Playwright's pinned Chromium + its OS dependencies, matching this repo's playwright version.
# The browser lives at a user-independent path so it is found regardless of the container user and
# persists across container rebuilds. Copy only the manifests so this layer caches unless the
# lockfile changes. On a Playwright version bump the repo's playwright re-downloads the browser in
# postCreate onto these baked OS deps; rebuild the image (`devcontainer up --build`) only if a new
# version ever needs additional OS libraries.
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
WORKDIR /tmp/pw
COPY package.json package-lock.json ./
RUN PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci \
  && npx --yes playwright install --with-deps chromium \
  && rm -rf node_modules
WORKDIR /workspaces
