FROM debian:stretch-slim

LABEL maintainer="Ammar K."

ENV LISTEN_ADDRESS="" \
    LISTEN_PORT=8080 \
    MANAGEMENT_INTERFACE_ADDRESS="" \
    MANAGEMENT_INTERFACE_PORT=6082 \
    BACKEND_DEFAULT_HOST=127.0.0.1 \
    BACKEND_DEFAULT_PORT=8080 \
    VSL_RECLEN=255 \
    MALLOC=256m

COPY config/default.vcl.template /etc/varnish/
COPY docker-entrypoint.sh /usr/local/bin/

RUN set -x \
    && gettext='gettext-base' \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        $gettext \
        libssl-dev \
        varnish \
    && mv /usr/bin/envsubst /tmp/ \
    && apt-get purge -y --auto-remove $gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    && ln -s usr/local/bin/docker-entrypoint.sh / # backward compatibility

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE $LISTEN_PORT $MANAGEMENT_INTERFACE_PORT
CMD ["varnishd"]
