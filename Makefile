MAKEFLAGS += -s

clean:
	echo "Cleaning up artifacts..."
	rm -rf ./dist

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
	docker cp app-builder:/app/dist/ ./dist
	docker rm app-builder

build-no-cache:
	make clean
	echo "Building page..."
	docker buildx build --no-cache -t cv:latest .
	docker run --name app-builder cv:compose
	docker cp app-builder:/app/dist/ ./dist
	docker rm app-builder

app-builder-logs:
	docker compose logs -f app-builder

webserver-logs:
	docker compose logs -f webserver

certbot-logs:
	docker compose logs -f certbot

run:
	docker compose up -d

stop-webserver:
	echo "Stopping webserver..."
	-docker stop webserver > /dev/null 2>&1

remove-webserver:
	make stop-webserver
	echo "Removing container..."
	-docker rm cv-app > /dev/null 2>&1

restart-webserver:
	echo "Restarting webserver..."
	docker restart webserver

certificates:
	echo "Creating certificates..."
	docker exec -it cv-app certbot --nginx -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev

certificates-compose:
	echo "Creating certificates..."
	docker-compose run --rm certbot certonly --webroot --webroot-path /usr/share/nginx/html --dry-run -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev

webserver-ssl-config:
	echo "Creating SSL configuration..."
	docker exec webserver cp /etc/nginx/sites-available/valerio-ssl.dev /etc/nginx/sites-available/valerio.dev

serve:
	make stop-container
	make remove-container
	make run
	make certificates
	make nginx-ssl-config
	make restart-nginx

all:
	make clean
	make build
	make serve
