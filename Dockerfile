FROM python:alpine
ENV PYTHONUNBUFFERED 1
ENV C_FORCE_ROOT true
RUN mkdir /src
RUN mkdir /env
RUN mkdir /nginx_config
ADD env/docker_django /build_env
COPY scripts /scripts
RUN /scripts/build_env.sh
CMD echo "################# " `date` " #####################" >>  /run/start_django.log
CMD /scripts/start_django.sh  >> /run/start_django.log 2>&1
