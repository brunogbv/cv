MAKEFLAGS += -s

build:
	docker build -t cv .

run:
	docker run -d -p 80:80 -p 443:443 --name cv-app cv:latest > /dev/null

copy:
	docker cp cv-app:/usr/share/nginx/html .

stop-container:
	-docker stop cv-app > /dev/null

remove-container:
	-docker rm cv-app > /dev/null

remove-image:
	-docker image rm cv:latest > /dev/null

clean:
	echo "Cleaning up artifacts..."
	make stop-container > /dev/null 2>&1
	make remove-container > /dev/null 2>&1
	make remove-image > /dev/null 2>&1

html:
	make clean
	make build
	make run
	make copy
	make clean

nginx:
	docker exec -it cv-app nginx -g 'daemon off;'

serve:
	make stop-container
	make remove-container
	make run

all:
	make clean
	make build
	make serve