FROM python:alpine
ENV PYTHONUNBUFFERED 1
ENV C_FORCE_ROOT true
RUN mkdir /src
RUN mkdir /env
RUN mkdir /nginx_config
ADD env/docker_django /build_env
COPY scripts /scripts
RUN /scripts/build_env.sh
CMD /scripts/start_django.sh 
