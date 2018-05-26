#!/bin/bash
function dockers_up() {

	if [ ! -z "$BROKER_PROTOCOL" ]; then
		docker-compose up -d broker-$BROKER_PROTOCOL
	fi

	if [ ! -z "$DB_ENGINE" ]; then
		case "$DB_ENGINE" in
			postgresql_psycopg2)
                		DB_SERVER="postgres"
		        ;;

			*)
				DB_SERVER=""

			;;
		esac


		if [ ! -z "$DB_SERVER" ]; then
			docker-compose up -d db-$DB_SERVER
		fi
	fi

	docker-compose up -d nginx
	docker-compose up -d django

}

function get_container_id() {
  docker ps -aqf "name=$1"
}

function docker_exec() {
	docker exec -it --tty=false $1 "$2" 2>&1
}


function build_nginx() {
	STATIC_ROOT_CONF=""

	if [ "${STATIC_ROOT:0:2}" = "./" ]; then
		STATIC_ROOT="/src/"$DJANGO_ROOT"/"${STATIC_ROOT:2}
	fi

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
	sed -i 's/^'$1'=.*$/'$1'='$2'/' env/docker_django
}

function build_broker() {
	if [ -z "$BROKER_PORT" ]; then
		BROKER_PORT=0
	fi

	change_env BROKER_PORT $BROKER_PORT
	change_env BROKER_PROTOCOL $BROKER_PROTOCOL
}

function load_django_env() {
	. env/docker_django
}


function build_django () {
	rm -f src/docker_django_built

	docker-compose build
	yes | docker-compose up -d django

	echo "Waiting django to start"
	sleep 5

	container_id=$(get_container_id django)
	while [ ! -f "src/docker_django_built" ]; do
		container_id=$(get_container_id django)
		if [ -z "$container_id" ]; then
			echo "Build failed :("
			return 1
		fi

		sleep 3
	done

	# Need to build and start django to understand whatelse is needed
	load_django_env

	docker stop $container_id

}

function build_postgres () {
	if [ -z "$DB_PORT" ]; then
		DB_PORT=0
	fi

	change_env DB_USER $DB_USER
	change_env DB_NAME $DB_NAME
	change_env DB_PASSWORD $DB_PASSWORD
	change_env DB_PORT $DB_PORT
	change_env DB_HOST $DB_HOST
}

function build_empty () {
        build_broker
        build_postgres
}

function build () {
	# avoid errors
	build_empty

	build_django
	build_nginx

	if [ ! -z "$BROKER_PROTOCOL" ]; then
		build_broker
	fi

        if [ ! -z "$DB_ENGINE" ]; then
                case "$DB_ENGINE" in
                        postgresql_psycopg2)
                                build_postgres
                        ;;

                        *)
				echo "I cant build database $DB_ENGINE"
                        ;;
                esac
	fi

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


function clean() {
	dockers_stop 2> /dev/null
	# TODO: dockers rm images

	rm -rf src

}

function main () {
	if [ ! -f "env/docker_django" ]; then
		echo "You need to create './env/docker_django' try to pick one example from the directory ./env/"
		exit 1
	fi

	
	ln -sf  env/docker_django .env
	load_django_env


	case "$1" in
		up)
			dockers_up
		;;

		start)
			dockers_up
		;;

		stop)
			dockers_stop
		;;

		build)
			build
		;;

		clean)
			clean
		;;


		*)
			echo "Command not recognized"
		;;
	esac

}


main $@
