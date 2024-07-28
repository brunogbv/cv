# Use a base image with Node.js installed
FROM node:14 AS builder

ARG USERNAME=builder
ARG USER_UID=1001
ARG USER_GID=$USER_UID
ARG WORKDIR=/app
# Set the working directory
WORKDIR $WORKDIR

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  #
  # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
  && apt-get update \
  && apt-get install -y $(ldd chrome | grep not | awk '{print $1}') \
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
COPY .nginx/valerio.dev /etc/nginx/sites-available/valerio.dev
COPY .nginx/nginx.conf /etc/nginx/nginx.conf
RUN ln -s /etc/nginx/sites-available/valerio.dev /etc/nginx/sites-enabled/valerio.dev

# Expose ports 80 and 443
EXPOSE 80 443

# Copy the script to obtain SSL certificate
RUN mkdir -p /usr/share/nginx/html/.well-known/acme-challenge
RUN mkdir -p /etc/letsencrypt/live/
COPY init-letsencrypt.sh /app/init-letsencrypt.sh
RUN chmod +x /app/init-letsencrypt.sh

# Run the init-letsencrypt.sh script during container startup
CMD ["/bin/bash", "-c", "/app/init-letsencrypt.sh"]