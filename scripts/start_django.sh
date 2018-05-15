#!/bin/sh
. /.env
. /venv/bin/activate

cd /src/
git clone $GIT_REPO . || git pull .

if [ -f "$PIP_REQUIREMENTS" ]; then
       pip install -r $PIP_REQUIREMENTS 
fi

/scripts/build_nginx_config.sh

cd /src/$DJANGO_ROOT
python manage.py migrate
python manage.py collectstatic  --noinput
gunicorn $DJANGO_WSGI -b $LISTEN_IP:$LISTEN_PORT
