# Use a base image with Node.js installed
FROM node:14 AS builder

HEALTHCHECK CMD curl --fail http://localhost:3000 || exit 1",

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

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
  && apt-get install -y --no-install-recommends wget=1.20.1-1.1 gnupg=2.2.12-1+deb10u2 \
  && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update \
  && apt-get install -y --no-install-recommends google-chrome-stable=127.0.6533.72 fonts-ipafont-gothic=00303-18 fonts-wqy-zenhei=0.9.45-7 \
  fonts-thai-tlwg=1:0.7.1-1 fonts-kacst=2.01+mry-14 fonts-freefont-ttf=20120503-9 libxss1=1:1.2.3-1 \
  && rm -rf /var/lib/apt/lists/*

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  #
  && apt-get update \
  && chown -R $USERNAME:$USERNAME $WORKDIR

USER $USERNAME

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application code to the working directory
COPY . .

# Build the application
RUN npm run build
