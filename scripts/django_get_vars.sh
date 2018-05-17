#!/bin/sh
. /.env
. /venv/bin/activate

python /src/$DJANGO_ROOT/manage.py shell < /scripts/django_get_vars.py

