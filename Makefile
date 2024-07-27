build:
	docker build -t cv .

run:
	docker run -d --name my-running-app cv:latest

copy:
	docker cp my-running-app:/usr/share/nginx/html .

run:
	docker run -d -p 80:80 -p 443:443 --name my-running-app cv:latest

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
	docker run -d -p 80:80 -p 443:443 --name my-running-app cv:latest