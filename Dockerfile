# Build the CV (HTML + PDF) on a modern Node LTS.
FROM node:22-bookworm-slim AS builder

ARG WORKDIR=/app
WORKDIR $WORKDIR

# make is needed for `make page`.
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends make \
  && rm -rf /var/lib/apt/lists/*

# Install dependencies, then the Chromium build pinned to this Playwright
# version (recorded in package-lock.json) plus its OS dependencies, for the
# image's architecture. This works natively on both amd64 and arm64, so the
# build is reproducible without emulation.
COPY package*.json ./
RUN npm ci \
  && npx --yes playwright install --with-deps chromium

# Copy the rest of the application code and build.
COPY . .
CMD ["make", "page"]
