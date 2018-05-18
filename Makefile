build:
	scripts/docker_django.sh build

start:
	scripts/docker_django.sh start

stop:
	scripts/docker_django.sh stop

restart:
	scripts/docker_django.sh stop && scripts/docker_django.sh start

