#!/bin/bash

TEMP_NGINX_CONF=".nginx/temp.conf"
REGULAR_NGINX_CONF=".nginx/valerio.dev"

if [ ! -d "/etc/letsencrypt/live/valerio.dev" ]; then
  echo "### Starting Nginx with temporary configuration ..."
  cp -w $TEMP_NGINX_CONF /etc/nginx/sites-available/valerio.dev
  nginx -g 'daemon off;' &

  echo "### Requesting Let's Encrypt certificate for valerio.dev ..."
  certbot certonly --webroot -w /usr/share/nginx/html -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev

  echo "### Stopping temporary Nginx ..."
  pkill nginx

  echo "### Removing temporary configuration ..."
  cp -w $REGULAR_NGINX_CONF /etc/nginx/sites-available/valerio.dev

  echo "### Switching to regular Nginx configuration ..."
  nginx -s reload
else
  echo "### SSL certificate already exists for valerio.dev."
fi