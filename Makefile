MAKEFLAGS += -s

build:
	echo "Building image..."
	docker build -t cv .

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

clean:
	echo "Cleaning up artifacts..."
	make stop-container
	make remove-container
	make remove-image

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

serve:
	make stop-container
	make remove-container
	make certificates
	make restart-nginx
	make run

all:
	make clean
	make build
	make serve