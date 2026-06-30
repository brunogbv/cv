# Build the CV (HTML + PDF) on a modern Node LTS.
FROM node:22-bookworm-slim AS builder

ARG WORKDIR=/app
WORKDIR $WORKDIR

# Use the distro Chromium for Puppeteer instead of downloading its own copy.
ENV PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# make (for `make page`), Chromium for Puppeteer, and fonts for broad charset
# coverage (Chinese, Japanese, Arabic, etc.).
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    make \
    chromium \
    ca-certificates \
    fonts-liberation \
    fonts-freefont-ttf \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
  && rm -rf /var/lib/apt/lists/*

# Install dependencies (Puppeteer skips its Chromium download via the env above).
COPY package*.json ./
RUN npm ci

# Copy the rest of the application code and build.
COPY . .
CMD ["make", "page"]
