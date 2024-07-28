# Use a base image with Node.js installed
FROM node:14 AS builder

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
  # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
  && apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME \
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

# Use a lightweight base image
FROM nginx:alpine

# Copy the built files from the builder stage to the nginx web root directory
COPY --from=builder /app/dist /usr/share/nginx/html

RUN apk update && \
  apk add --no-cache certbot-nginx bash && \
  rm -rf /var/cache/apk/*

RUN mkdir /etc/nginx/sites-available
RUN mkdir /etc/nginx/sites-enabled
COPY .nginx/temp.conf /etc/nginx/sites-available/valerio.dev
COPY .nginx/valerio-ssl.dev /etc/nginx/sites-available/valerio-ssl.dev
COPY .nginx/nginx.conf /etc/nginx/nginx.conf
RUN ln -s /etc/nginx/sites-available/valerio.dev /etc/nginx/sites-enabled/valerio.dev

# Expose ports 80 and 443
EXPOSE 80 443

# Copy the script to obtain SSL certificate
RUN mkdir -p /usr/share/nginx/html/.well-known/acme-challenge
RUN mkdir -p /etc/letsencrypt/live/

