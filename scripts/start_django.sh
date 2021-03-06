#!/bin/sh
set -ix

. /env/docker_django
. /venv/bin/activate

cd /src/
git clone $GIT_REPO . || git pull .

if [ ! -z "$GIT_POSTEXEC" ]; then
	sh -c "$GIT_POSTEXEC"
fi

if [ -f "$PIP_REQUIREMENTS" ]; then
       pip install -r $PIP_REQUIREMENTS 
fi

python /src/$DJANGO_ROOT/manage.py shell < /scripts/django_get_vars.py
. /env/docker_django

settings_relative=$( echo $DJANGO_SETTINGS_MODULE | sed 's/\./\//g' )
settings_path="/src/"$DJANGO_ROOT"/"$settings_relative".py"

if [ "$ADD_ALLOWED_HOSTS" = "1" ] && [ ! -z "$DJANGO_SETTINGS_MODULE" ] && [ ! -f "/run/added_allowed_hosts" ]; then
        echo $settings_path > /run/added_allowed_hosts
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

if [ ! -z "$DB_HOST" ]; then
	echo "Waiting database to start $DB_HOST:$DB_PORT ..."
	for i in $(seq 1 10); do
		nc -z $DB_HOST $DB_PORT && break
		sleep 5
	done
	echo "Waiting finished..."
fi

touch /run/docker_django_built
cd /src/$DJANGO_ROOT
python manage.py migrate
python manage.py collectstatic  --noinput
gunicorn $DJANGO_WSGI -b $LISTEN_IP:$LISTEN_PORT
