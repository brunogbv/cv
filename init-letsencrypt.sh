#!/bin/bash

if [ ! -d "/etc/letsencrypt/live/valerio.dev" ]; then
  echo "### Requesting Let's Encrypt certificate for valerio.dev ..."
  certbot certonly --webroot -w /usr/share/nginx/html -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev
else
  echo "### SSL certificate already exists for valerio.dev."
fi