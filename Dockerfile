FROM nginx:alpine

RUN addgroup -g 1000 node \
    && adduser -u 1000 -G node -s /bin/sh -D node

RUN apk update && apk add nodejs yarn

ENV OPENEATS_VERSION=master \
    PATH=/usr/local/bin:$PATH \
    # nginx config
    API_HOST=0.0.0.0 \
    API_PORT=8000 \
    # Database config
    MYSQL_HOST=localhost \
    MYSQL_PORT=3306 \
    MYSQL_DATABASE=openeats \
    MYSQL_USER=openeats \
    MYSQL_PASSWORD=openeats \
    MYSQL_ROOT_PASSWORD=openeats \
    # Django config
    SUPERUSER_NAME=openeats \
    SUPERUSER_PASSWORD=openeats \
    API_URL=0.0.0.0:8000 \
    DJANGO_SETTINGS_MODULE=base.settings \
    DJANGO_DEBUG=False \
    HTTP_X_FORWARDED_PROTO=true \
    # Node config
    NODE_ENV=production \
    NODE_URL=http://localhost:8080 \
    NODE_LOCALE=en \
    APP_VERSION=0.2

COPY default.conf /etc/nginx/conf.d/default.conf
COPY start.sh /startup/

RUN apk add --update-cache --update --virtual builddeps \
        # fetch deps
        tar \
        openssl \
        ca-certificates \
        # pillow deps
        python3-dev \
        libjpeg-turbo-dev \
        gcc \
        musl-dev && \
    apk add --update-cache --update \
        mariadb-dev \
        py3-pip \
        python3 && \
    cd /tmp && \
    wget -O openeats-web.tar.gz "https://github.com/jzyrobert/openeats-web/archive/$OPENEATS_VERSION.tar.gz" && \
    wget -O openeats-api.tar.gz "https://github.com/jzyrobert/openeats-api/archive/$OPENEATS_VERSION.tar.gz" && \
    tar -xzf openeats-web.tar.gz && rm openeats-web.tar.gz && mv openeats-web-$OPENEATS_VERSION /openeats-web && \
    tar -xzf openeats-api.tar.gz && rm openeats-api.tar.gz && mv openeats-api-$OPENEATS_VERSION /code && \
    mkdir -p /var/www/html/openeats-static /code/static-files /code/site-media && \
    ln -s /code/static-files /var/www/html/openeats-static/ && \
    ln -s /code/site-media /var/www/html/openeats-static/ && \
    ln -s /usr/bin/python3 /usr/local/bin/python && \
    chmod 755 /startup /code/base/prod-entrypoint.sh && \
    pip3 install -r /code/base/requirements.txt && \
    cd /openeats-web && yarn install --pure-lockfile --production=false && yarn start && \
    ln -s /openeats-web/build /var/www/html/openeats-static/public-ui && \
    apk del builddeps && \
    chmod -R 755 /startup

CMD ["/startup/start.sh"]