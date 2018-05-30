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

			mysql)
				DB_SERVER="mysql"
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

	echo -e "\n\n\n\n#########################################"
	echo "Running on: http://$LISTEN_IP:$LISTEN_PORT"
	echo -e "#########################################\n\n\n\n"

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
	rm -f run/docker_django_built

	docker-compose build
	yes  | dockers_up > /dev/null 2>&1

	echo "Waiting django to start"
	sleep 10

	container_id=$(get_container_id django)
	while [ ! -f "run/docker_django_built" ]; do
		container_id=$(get_container_id django)
		if [ -z "$container_id" ]; then
			echo "Build failed :("
			return 1
		fi

		sleep 3
	done

	# Need to build and start django to understand whatelse is needed
	load_django_env

#	docker stop $container_id
	dockers_stop > /dev/null 2>&1

}

function build_database () {
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
        build_database
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
                        postgresql_psycopg2|mysql)
                                build_database
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

	echo "Stopping broker..."
	docker stop $(get_container_id broker-redis) 

	echo "Stopping database..."
        docker stop $(get_container_id db-postgres)
        docker stop $(get_container_id db-mysql)

}


function clean() {
	dockers_stop 2> /dev/null 
	rm -rf run
	mkdir run

	rm -rf src
	mkdir src
	# TODO: dockers rm images

}

# TODO: Generate a SECRET_KEY
function write_env() {
        cat > env/docker_django << __EOF__

GIT_REPO="$GIT_REPO"
GIT_POSTEXEC="$GIT_POSTEXEC"
PIP_REQUIREMENTS="$PIP_REQUIREMENTS"
# Path to Django project root where manage.py is located
DJANGO_ROOT="$DJANGO_ROOT"
# DOT path to gunicorn
DJANGO_WSGI="$DJANGO_WSGI"
LISTEN_IP="0.0.0.0"
LISTEN_PORT=$LISTEN_PORT
ADD_ALLOWED_HOSTS=1
APK_ADD=""
DB_PORT=0
DB_PASSWORD=
DB_USER=
DB_NAME=
DB_HOST=
BROKER_PORT=0
SECRET_KEY='+b^b8\$tod3je_f85xb_35rvd)cabazmk@)i1-0*r!\$cy6p646@'

__EOF__


}


function config () {
	if [ -z "$LISTEN_PORT" ]; then
		LISTEN_PORT=7778
	fi

	echo "Cleaning..."
        clean > /dev/null 2>&1
        mkdir -p src
        git clone $GIT_REPO src > /dev/null 2>&1
        cd src

        PIP_REQUIREMENTS=$(find . -type f -name '*requirements*' | head -1  | sed 's/\.\///')
        DJANGO_ROOT=$(find . -name manage.py | head -1 | sed 's/\/manage\.py//' | sed 's/\.\///')
        DJANGO_WSGI=$(find . -name wsgi.py  | sed 's/\.\/'$DJANGO_ROOT'\/*//' | sed 's/\//\./g' | sed 's/\.py$//')
        GIT_POSTEXEC=""
        if [ -f "setup.py" ]; then
                GIT_POSTEXEC=$GIT_POSTEXEC" python setup.py install;"
        fi

	# Requirements adjustements: we shouldn't do it. 
	# TODO: suggest
        if [ ! -z "$PIP_REQUIREMENTS" ]; then
                if [ "$(grep 'psycopg2==2.6.2' $PIP_REQUIREMENTS)" != "" ]; then
                        GIT_POSTEXEC=$GIT_POSTEXEC" sed -i s/psycopg2==2.6.2/psycopg2/ $PIP_REQUIREMENTS;"
                fi
                if [ "$(grep 'MySQL-python' $PIP_REQUIREMENTS)" != "" ]; then
 			# Python3 support
                       GIT_POSTEXEC=$GIT_POSTEXEC" sed -i s/MySQL-python*$/mysqlclient/ $PIP_REQUIREMENTS;"
                fi
        fi

	find . -name settings.py | while read settings; do
		if [ "$(grep SECRET_KEY $settings)" = "" ]; then
			GIT_POSTEXEC=$GIT_POSTEXEC" echo SECRET_KEY = '$SECRET_KEY' >> $settings;"

			echo "aqui $GIT_POSTEXEC"
		fi
	done

        cd ..
        write_env

	echo -e "Please check 'env/docker_django' before executing:\n\n"
	echo -e "make build && make start\n\n"

}

function check_env () {
	if [ ! -f "env/docker_django" ]; then
		echo "You need to create './env/docker_django' try to pick one example from the directory ./env/ or use:"
		echo "./config.sh"
		exit 1
	else
		load_django_env
	fi
}

function main () {
	mkdir -p run	
	ln -sf  env/docker_django .env

	case "$1" in
		up)
			check_env
			dockers_up
		;;

		start)
			check_env
			dockers_up
		;;

		stop)
			check_env
			dockers_stop
		;;

		build)
			check_env
			build
		;;

		clean)
			check_env
			clean
		;;

		config)
			GIT_REPO=$2
			LISTEN_PORT=$3

			config
		;;

		*)
			echo "Command not recognized"
		;;
	esac

}


main $@
