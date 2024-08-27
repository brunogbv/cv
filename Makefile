MAKEFLAGS += -s

# Build the page using local environment
# Dependencies: npm, node
make page:
	echo "Building page..."
	-rm -rf ./dist/ > /dev/null 2>&1
	npm run build

lint:
	docker run --rm \
		-e LOG_LEVEL=INFO \
		-e RUN_LOCAL=true \
    --env-file "config/lint/super-linter.env" \
		-v $(shell pwd):/tmp/lint \
		ghcr.io/super-linter/super-linter:latest

# Build the page using dockerized environment
# Useful for deploying the page to a server when certificates are already created
# output will be stored in the container's /app/dist folder and mounted to shared volume cv_dist
build:
	echo "Building page..."
	make remove-app-builder
	docker compose up --build app-builder

# Build the page using dockerized environment and copy files to local dist folder
# Useful for building the page without having to install dependencies on local machine
# Same as make page, but no dependency requirements on local machine
dev-build:
	echo "Building page..."
	make remove-app-builder
	make build
	docker cp app-builder:/app/dist ./dist

# Get the logs of the app-builder, useful for debugging build issues
logs-app-builder:
	docker compose logs -f app-builder

# Get the logs of the webserver, useful for debugging nginx issues
logs-webserver:
	docker compose logs -f webserver

# Get the logs of the certbot, useful for debugging issues when creating certificates
logs-certbot:
	docker compose logs -f certbot

# Useful if you need to remove the app-builder container
remove-app-builder:
	echo "Removing build container..."
	-docker rm -f app-builder > /dev/null 2>&1

# Useful if you need to remove the certbot container
remove-certbot:
	echo "Removing certbot..."
	-docker rm-f certbot > /dev/null 2>&1
	-docker rm-f certbot-dry-run > /dev/null 2>&1

# Create certificates using dockerized certbot
# certs are stored in ./certbot/conf/live/valerio.dev/ and mounted to shared volume cv_certs
certificates:
	echo "Creating certificates..."
	docker compose up certbot
	make remove-certbot

# Create certificates using dockerized certbot
# certs are stored in ./certbot/conf/live/valerio.dev/ and mounted to shared volume cv_certs
certificates-dry-run:
	echo "Creating certificates (dry run)..."
	docker compose up certbot-dry-run
	make remove-certbot

# Updates the nginx configuration to use the newly created certificates
# Enables SSL and redirects all HTTP traffic to HTTPS
webserver-ssl-config:
	echo "Creating SSL configuration..."
	docker exec webserver cp /etc/nginx/sites-available/valerio-ssl.conf /etc/nginx/sites-available/valerio.dev

# Restarts the nginx server to apply new configurations
webserver-restart-nginx:
	echo "Restarting nginx..."
	docker exec webserver nginx -s reload

# Upgrades the webserver to use HTTPS
# This is the main command to run to enable HTTPS on the webserver
webserver-upgrade-to-https:
	make certificates
	make webserver-ssl-config
	make webserver-restart-nginx

# Downs the webserver
down:
	echo "Downing webserver..."
	docker compose down

# Adds localhost to nginx server_name
# Useful for local development
webserver-local:
	echo "Hosting nginx..."
	docker buildx build --build-arg SITE_NAME=valerio-local.conf -t valerio.dev:local
	docker compose up -d webserver

# Starts the webserver
webserver:
	echo "Hosting nginx..."
	docker compose up -d --build webserver

# Full build and deploy
# Useful for deploying the page to a server for the first time
# Avoid running this command if you are just updating the page as it will recreate the certificates
all:
	make build
	make webserver
	make webserver-upgrade-to-https

