#!/bin/bash
. .env


function dockers_up() {
	docker-compose up -d nginx
	docker-compose up -d django

	if [ ! -z "$BROKER_PROTOCOL" ]; then
		docker-compose up -d broker-$BROKER_PROTOCOL
	fi
}

function get_container_id() {
  docker ps -aqf "name=$1"
}

function docker_exec() {
	docker exec -it --tty=false $1 "$2" 2>&1
}


function build_nginx() {

	STATIC_ROOT_CONF=""
	if [ ! -z "$STATIC_ROOT" ] && [ ! -z "$STATIC_URL" ]; then
		STATIC_ROOT_CONF="location $STATIC_URL { autoindex on; alias $STATIC_ROOT/; }"
	fi

	mkdir -p nginx_config
	cat > nginx_config/mydjango.conf << __EOF__

upstream django {  
  ip_hash;
  server django:$LISTEN_PORT;
}

server {

    $STATIC_ROOT_CONF

    location / {
        proxy_pass http://django/;
    }
    listen $LISTEN_PORT;
    server_name localhost;
}

__EOF__

}


function change_env() {
	cat .env | grep -v "^$1\=" > .env.new
	echo "$1='$2'" >> .env.new
	cat .env.new |  sed "s/'\([0-9]*\)'/\1/" > .env
	rm -f .env.new
}

function build_broker() {
	change_env BROKER_PORT $BROKER_PORT
	change_env BROKER_PROTOCOL $BROKER_PROTOCOL
}

function load_django_env() {
	container_id=$(get_container_id django)
	eval $(docker_exec $container_id /scripts/django_get_vars.sh)
	. src/django_env
}

function build () {
	# avoid errors
        change_env BROKER_PORT 0
        change_env BROKER_PROTOCOL ""


	docker-compose build
	yes | docker-compose up -d django
	sleep 5
	echo "Waiting django to start"
	container_id=$(get_container_id django)
	while [ "$(docker_exec $container_id ps | grep gunicorn | grep -v grep | grep -v pip)" = "" ]; do
		sleep 1
	done

	load_django_env
	docker stop $container_id
	build_nginx
	build_broker

}

function dockers_stop() {
	echo "Stopping nginx..."
	docker stop $(get_container_id nginx)

	echo "Stopping django..."
	docker stop $(get_container_id django)

	if [ ! -z "$BROKER_PROTOCOL" ]; then
		echo "Stopping message broker..."
		docker stop $(get_container_id broker-$BROKER_PROTOCOL)
	fi

}

case "$1" in
	up)
		dockers_up;
	;;

	start)
		dockers_up;
	;;

	stop)
		dockers_stop;
	;;

	build)
		build;
	;;

	*)
		echo "Command not recognized"
	;;
esac
