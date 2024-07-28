# Use a base image with Node.js installed
FROM node:14 AS builder

HEALTHCHECK CMD curl --fail http://localhost:3000 || exit 1",

ARG USERNAME=builder
ARG USER_UID=1001
ARG USER_GID=$USER_UID
ARG WORKDIR=/app
# Set the working directory
WORKDIR $WORKDIR

# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN apt-get update \
  && apt-get install -y wget gnupg \
  && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update \
  && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
  --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  #
  && apt-get update \
  && chown -R $USERNAME:$USERNAME $WORKDIR

USER $USERNAME

# Copy the application code to the working directory
COPY . .

# Install dependencies
RUN npm ci && npm run build
