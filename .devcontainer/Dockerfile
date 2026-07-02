# Dev Container image for the CV repo.
#
# Bakes the heavy, workspace-INDEPENDENT tooling into the image so it persists across container
# rebuilds and is cheap per git worktree. Workspace-specific dependencies (node_modules) stay in
# postCreate. See docs/local-development.md.
#
# Base image pinned by digest for reproducibility (constitution Principle V — "pin what determines
# output"). The tag is kept for readability; the digest is what actually pins. This is the multi-arch
# *index* digest, so it resolves on both amd64 (CI) and arm64 (Apple Silicon). To refresh on an
# intentional base bump, re-resolve the tag's index digest and update the digest below:
#   curl -sSI -H 'Accept: application/vnd.oci.image.index.v1+json' \
#     https://mcr.microsoft.com/v2/devcontainers/javascript-node/manifests/22-bookworm \
#     | grep -i docker-content-digest
FROM mcr.microsoft.com/devcontainers/javascript-node:22-bookworm@sha256:92e97da1df8f4135188053b3a5e22e3ef316ecaf2a0d33b8831e1dec5cdaa77f

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# The Dev Container runs as root by design (devcontainer.json sets remoteUser: root), and the build
# steps below need root (apt via playwright --with-deps, global npm/uv installs).
# hadolint ignore=DL3002
USER root

# uv + the spec-kit `specify` CLI (workspace-independent), both version-pinned for reproducibility
# (constitution Principle V). To bump: change the uv version in the installer URL
# (https://astral.sh/uv/<version>/install.sh) and the spec-kit tag (@vX.Y.Z from
# https://github.com/github/spec-kit/releases). uv's standalone installer needs no Python.
RUN curl -LsSf https://astral.sh/uv/0.11.26/install.sh | UV_INSTALL_DIR=/usr/local/bin sh \
  && UV_TOOL_BIN_DIR=/usr/local/bin uv tool install \
    --from git+https://github.com/github/spec-kit.git@v0.12.4 specify-cli

# Claude Code CLI (workspace-independent global). Intentionally NOT pinned — it's agent tooling we
# want fresh, and (like the `gh` CLI from the github-cli feature) it doesn't affect the CV build
# output, so it's outside Principle V's "pin what determines output". See docs/local-development.md.
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
