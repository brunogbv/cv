MAKEFLAGS += -s

make page:
	echo "Building page..."
	rm -rf ./dist/
	npm run build

lint:
	docker run --rm \
		-e LOG_LEVEL=INFO \
		-e RUN_LOCAL=true \
    --env-file "config/lint/super-linter.env" \
		-v $(shell pwd):/tmp/lint \
		ghcr.io/super-linter/super-linter:latest

build:
	make remove-app-builder
	# docker volume rm cv_html
	echo "Building page..."
	docker compose up --build app-builder
	make remove-app-builder

build-no-cache:
	echo "Building page..."
	make remove-app-builder
	docker buildx build --no-cache -t cv:latest .
	docker run --name app-builder cv:compose
	make remove-app-builder

logs-app-builder-:
	docker compose logs -f app-builder

logs-webserver:
	docker compose logs -f webserver

logs-certbot:
	docker compose logs -f certbot

stop-webserver:
	echo "Stopping webserver..."
	-docker stop webserver > /dev/null 2>&1

remove-app-builder:
	echo "Removing build container..."
	-docker rm -f app-builder > /dev/null 2>&1

remove-certbot:
	echo "Removing certbot..."
	-docker rm-f webserver > /dev/null 2>&1

remove-webserver:
	echo "Removing container..."
	-docker rm -f webserver > /dev/null 2>&1

restart-webserver:
	echo "Restarting webserver..."
	docker restart webserver

certificates:
	echo "Creating certificates..."
	docker compose up certbot
	make remove-certbot

webserver-ssl-config:
	echo "Creating SSL configuration..."
	docker exec webserver cp /etc/nginx/sites-available/valerio-ssl.conf /etc/nginx/sites-available/valerio.dev

webserver-restart-nginx:
	echo "Restarting nginx..."
	docker exec webserver nginx -s reload

webserver-upgrade-to-https:
	make certificates
	make webserver-ssl-config
	make webserver-restart-nginx

down:
	echo "Downing webserver..."
	docker compose down

#Adds localhost to nginx server_name
webserver-local:
	echo "Hosting nginx..."
	docker buildx build --build-arg SITE_NAME=valerio-local.conf -t valerio.dev:local
	docker compose up -d webserver

webserver:
	echo "Hosting nginx..."
	docker compose up -d --build webserver

all:
	make build
	make webserver
	make webserver-upgrade-to-https

