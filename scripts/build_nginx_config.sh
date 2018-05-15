#!/bin/sh
. /DOCKER_DJANGO
. /venv/bin/activate

eval $(python /src/$DJANGO_ROOT/manage.py shell < /scripts/django_get_vars.py)

STATIC_ROOT_CONF=""
if [ ! -z "$STATIC_ROOT" ] && [ ! -z "$STATIC_URL" ]; then
	STATIC_ROOT_CONF="location $STATIC_URL { autoindex on; alias $STATIC_ROOT/; }"
fi

cat > /nginx_config/mydjango.conf << __EOF__

upstream web {  
  ip_hash;
  server web:$LISTEN_PORT;
}

server {

    $STATIC_ROOT_CONF

    location / {
        proxy_pass http://web/;
    }
    listen $LISTEN_PORT;
    server_name localhost;
}

__EOF__
