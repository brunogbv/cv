MAKEFLAGS += -s

build:
	docker build -t cv .

run:
	docker run -d -p 80:8080 -p 443:8081 --name cv-app cv:latest

copy:
	docker cp cv-app:/usr/share/nginx/html .

stop-container:
	-docker stop cv-app >> /dev/null

remove-container:
	-docker rm cv-app >> /dev/null

remove-image:
	-docker image rm cv:latest >> /dev/null

clean:
	@echo "Cleaning up artifacts..."
	@make stop-container
	@make remove-container
	@make remove-image

html:
	make clean
	make build
	make run
	make copy
	make clean

nginx:
	docker exec -it cv-app nginx -g 'daemon off;'

serve:
	make run
	make nginx

all:
	make clean
	make build
	make serve