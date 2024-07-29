MAKEFLAGS += -s

build:
	make clean
	echo "Building page..."
	docker compose up --build app-builder
	docker cp app-builder:/app/dist/ ./dist
	docker rm app-builder

build-no-cache:
	make clean
	echo "Building page..."
	docker compose up --build --no-cache app-builder
	docker cp app-builder:/app/dist/ ./dist
	docker rm app-builder

clean:
	echo "Cleaning up artifacts..."
	rm -rf ./dist

app-builder-logs:
	docker compose logs -f app-builder

webserver-logs:
	docker compose logs -f webserver

certbot-logs:
	docker compose logs -f certbot

lint:
	docker run --rm \
		-e LOG_LEVEL=INFO \
		-e RUN_LOCAL=true \
    --env-file "config/lint/super-linter.env" \
		-v $(shell pwd):/tmp/lint \
		ghcr.io/super-linter/super-linter:latest

run:
	echo "Running container..."
	docker run -d -p 80:80 -p 443:443 --name cv-app cv:latest > /dev/null

copy:
	docker cp cv-app:/usr/share/nginx/html .

stop-container:
	echo "Stopping container..."
	-docker stop cv-app > /dev/null 2>&1

remove-container:
	echo "Removing container..."
	-docker rm cv-app > /dev/null 2>&1

remove-image:
	echo "Removing image..."
	-docker image rm cv:latest > /dev/null 2>&1

html:
	make clean
	make build
	make run
	make copy
	make clean

nginx:
	docker exec -it cv-app nginx -g 'daemon off;'

restart-nginx:
	echo "Restarting Nginx..."
	docker exec -it cv-app nginx -s reload

certificates:
	echo "Creating certificates..."
	docker exec -it cv-app certbot --nginx -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev

certificates-compose:
	echo "Creating certificates..."
	docker-compose run --rm certbot certonly --webroot --webroot-path /usr/share/nginx/html --dry-run -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev

nginx-ssl-config:
	echo "Creating SSL configuration..."
	docker exec cv-app cp /etc/nginx/sites-available/valerio-ssl.dev /etc/nginx/sites-available/valerio.dev

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
