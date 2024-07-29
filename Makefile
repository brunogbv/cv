MAKEFLAGS += -s

clean:
	echo "Cleaning up artifacts..."
	rm -rf ./dist

copy:
	echo "Copying dist..."
	docker cp app-builder:/app/dist/ ./dist

lint:
	docker run --rm \
		-e LOG_LEVEL=INFO \
		-e RUN_LOCAL=true \
    --env-file "config/lint/super-linter.env" \
		-v $(shell pwd):/tmp/lint \
		ghcr.io/super-linter/super-linter:latest

build:
	make clean
	echo "Building page..."
	docker compose up -d --build app-builder
	make copy
	make remove-app-builder

build-no-cache:
	make clean
	echo "Building page..."
	docker buildx build --no-cache -t cv:latest .
	docker run --name app-builder cv:compose
	make copy
	make remove-app-builder

build-webserver-local:
	make clean
	echo "Building webserver..."
	docker buildx build --build-arg SITE_NAME=valerio-local.dev -t valerio.dev:local

app-builder-logs:
	docker compose logs -f app-builder

webserver-logs:
	docker compose logs -f webserver

certbot-logs:
	docker compose logs -f certbot

run:
	docker compose up -d

remove-app-builder:
	echo "Removing build container..."
	docker rm -f app-builder

stop-webserver:
	echo "Stopping webserver..."
	-docker stop webserver > /dev/null 2>&1

remove-webserver:
	echo "Removing container..."
	-docker rm -f webserver > /dev/null 2>&1

restart-webserver:
	echo "Restarting webserver..."
	docker restart webserver

certificates:
	echo "Creating certificates..."
	docker exec -it cv-app certbot --nginx -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev

certificates-compose:
	echo "Creating certificates..."
	# docker compose run --rm certbot certonly --webroot --webroot-path /usr/share/nginx/html --dry-run -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev
	docker compose up -d certbot

webserver-ssl-config:
	echo "Creating SSL configuration..."
	docker exec webserver cp /etc/nginx/sites-available/valerio-ssl.dev /etc/nginx/sites-available/valerio.dev

webserver-stop:
	echo "Downing webserver..."
	docker compose down

#Adds localhost to nginx server_name
webserver-local:
	make build-webserver-local
	docker compose up -d webserver
webserver:
	echo "Going online..."
	docker compose up -d --build webserver

online:
	docker compose down
	make remove-container
	make run
	make certificates
	make nginx-ssl-config
	make restart-nginx

all:
	make clean
	make build
	make serve
