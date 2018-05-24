#!/bin/sh
set -ix

. /.env
if [ -f "/src/django_env" ]; then
	. /src/django_env
fi

. /venv/bin/activate

cd /src/
git clone $GIT_REPO . || git pull .

if [ -f "$PIP_REQUIREMENTS" ]; then
       pip install -r $PIP_REQUIREMENTS 
fi

if [ ! -f "/src/django_env" ]; then
	/scripts/django_get_vars.sh
	. /src/django_env
fi

if [ "$ADD_ALLOWED_HOSTS" = "1" ] && [ ! -z "$DJANGO_SETTINGS_MODULE" ] && [ ! -f "/src/added_allowed_hosts" ]; then
        settings_relative=$( echo $DJANGO_SETTINGS_MODULE | sed 's/\./\//g' )
        settings_path="/src/"$DJANGO_ROOT"/"$settings_relative".py"

        echo $settings_path > /src/added_allowed_hosts

        cat >> $settings_path << __EOF__


# DOCKER-DJANGO ADDED
try:
        if 'django' not in ALLOWED_HOSTS:
                ALLOWED_HOSTS += ['django']
except:
        ALLOWED_HOSTS = ['django',]
# /DOCKER-DJANGO

__EOF__

fi



cd /src/$DJANGO_ROOT
python manage.py migrate
python manage.py collectstatic  --noinput
gunicorn $DJANGO_WSGI -b $LISTEN_IP:$LISTEN_PORT
