#!/bin/bash

function show_usage() {
	echo "Usage: $0 <git URL> [PORT]"
	echo -e "\n  ie.: $0 https://github.com/fredericowu/cognitivo 7778\n\n" 
	exit 1
}


function main() {
	
	if [ -z "$1" ]; then
		show_usage
	else
		scripts/docker_django.sh config $@
	fi

}


main $@
