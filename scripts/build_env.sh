#!/bin/sh
. /build_env

set -ex

# basic apk
# TODO: apk should install essentials only for each docker
apk update
apk add git postgresql-dev gcc musl-dev gcc libffi-dev zlib-dev jpeg-dev linux-headers mysql-dev
# creating virtual environment
python3.6 -m venv /venv
. /venv/bin/activate

# upgrade pip & install guinicorn
pip install -U pip
pip install gunicorn

# users apk
if [ ! -z "$APK_ADD" ]; then
	apk --no-cache add $APK_ADD
fi

