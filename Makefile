build:
	docker build -t cv .

run:
	docker run -d -p 80:8080 -p 443:8081 --name my-running-app cv:latest

copy:
	docker cp my-running-app:/usr/share/nginx/html .

stop-container:
	-docker stop my-running-app

remove-container:
	-docker rm my-running-app

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