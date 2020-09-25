FROM apfm/terraform-action-base:latest
WORKDIR /app

ENV MYCLI_VERSION 1.21.1
ENV PGCLI_VERSION 2.2.0

RUN set -e \
    && apk add --no-cache \
        build-base \
        postgresql-dev \
        python3-dev \
        py3-pip \
        postgresql-client \
        pwgen \
    && pip3 install --upgrade \
        mycli==${MYCLI_VERSION} \
        pgcli==${PGCLI_VERSION} \
    && apk --purge -v del \
        build-base \
        python3-dev \
    && rm -f /var/cache/apk/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh


#ENTRYPOINT ["/entrypoint.sh"]
ENTRYPOINT [ "/bin/sh" ]