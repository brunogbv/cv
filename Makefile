MAKEFLAGS += -s

build:
	docker build -t cv .

run:
	docker run -d -p 80:80 -p 443:443 --name cv-app cv:latest > /dev/null

copy:
	docker cp cv-app:/usr/share/nginx/html .

stop-container:
	-docker stop cv-app > /dev/null 2>&1

remove-container:
	-docker rm cv-app > /dev/null 2>&1

remove-image:
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
  docker exec -it cv-app nginx -s reload

certificates:
	docker exec -it cv-app certbot --nginx -d valerio.dev -d www.valerio.dev --non-interactive --agree-tos --email bruno@valerio.dev

serve:
	make stop-container
	make remove-container
	make run

all:
	make clean
	make build
	make run