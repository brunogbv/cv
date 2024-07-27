build:
	docker build -t cv .

run:
	docker run -d --name my-running-app cv:latest

copy:
	docker cp my-running-app:/usr/share/nginx/html .

clean:
	-docker stop my-running-app
	-docker rm my-running-app
	-docker image rm cv:latest

html:
	make clean
	make build
	make run
	make copy
	make clean

serve:
	make build
	docker run -d -p 80:80 --name my-running-app cv:latest