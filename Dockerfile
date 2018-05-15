FROM python:3.6-alpine
ENV PYTHONUNBUFFERED 1
ENV C_FORCE_ROOT true
RUN mkdir /src
RUN mkdir /nginx_config
COPY DOCKER_DJANGO /DOCKER_DJANGO
COPY scripts /scripts
RUN /scripts/build_env.sh
CMD /scripts/start_django.sh 
