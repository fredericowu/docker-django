#!/bin/sh
. /build_env

# basic apk
apk update
apk add git postgresql-dev gcc musl-dev

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

