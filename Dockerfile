FROM apfm/terraform-action-base:latest
WORKDIR /app

RUN set -e \
    && apk add --no-cache \
        build-base \
        postgresql-dev \
        python3-dev \
        py3-pip \
        postgresql-client \
        pwgen \
    && apk --purge -v del \
        build-base \
        python3-dev \
    && rm -f /var/cache/apk/*

RUN apk add --no-cache mycli --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/bin/sh" ]