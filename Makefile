build:
	scripts/docker_django.sh build

start:
	scripts/docker_django.sh start

stop:
	scripts/docker_django.sh stop

restart:
	scripts/docker_django.sh stop && scripts/docker_django.sh start

django-shell:
	docker exec -it `docker ps -aqf "name=django"` sh -c ". /.env; . /venv/bin/activate; sh"

manage-shell:
	docker exec -it `docker ps -aqf "name=django"` sh -c '. /.env; . /venv/bin/activate; python /src/$$DJANGO_ROOT/manage.py shell'


