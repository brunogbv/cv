build:
	docker build -t cv .

run:
	docker run -d -p 80:8080 -p 443:8081 --name cv-app cv:latest

copy:
	docker cp cv-app:/usr/share/nginx/html .

stop-container:
	-docker stop cv-app

remove-container:
	-docker rm cv-app

remove-image:
	-docker image rm cv:latest

clean:
	make stop-container
	make remove-container
	make remove-image

html:
	make clean
	make build
	make run
	make copy
	make clean

serve:
	make build
	make stop-container
	make remove-container
	make run