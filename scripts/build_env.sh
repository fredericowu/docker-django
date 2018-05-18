#!/bin/sh
. /.env

set -ex
apk update
apk add git postgresql-dev gcc musl-dev
python3.6 -m venv /venv
. /venv/bin/activate
pip install -U pip
pip install gunicorn

#runDeps="$( \
#            scanelf --needed --nobanner --recursive /venv \
#                    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
#                    | sort -u \
#                    | xargs -r apk info --installed \
#                    | sort -u \
#    )"

#apk add --virtual .python-rundeps $runDeps

if [ ! -z "$APK_ADD" ]; then
	apk --no-cache add $APK_ADD
fi

