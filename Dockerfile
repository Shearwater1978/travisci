FROM ubuntu:18.04

ENV CLICKHOUSE_SERVER_HOME=/opt/ch/

ARG repository="deb http://repo.yandex.ru/clickhouse/deb/stable/ main/"
ARG version=20.1.9.*
ARG gosu_ver=1.10

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        apt-transport-https \
        dirmngr \
        gnupg \
		tofrodos \
    && mkdir -p /etc/apt/sources.list.d \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4 \
    && echo $repository > /etc/apt/sources.list.d/clickhouse.list \
    && apt-get update \
    && env DEBIAN_FRONTEND=noninteractive \
        apt-get install --allow-unauthenticated --yes --no-install-recommends \
            clickhouse-common-static=$version \
            clickhouse-client=$version \
            clickhouse-server=$version \
            locales \
            tzdata \
            wget \
    && rm -rf \
        /var/lib/apt/lists/* \
        /var/cache/debconf \
        /tmp/* \
    && apt-get clean \
    && wget https://github.com/tianon/gosu/releases/download/${gosu_ver}/gosu-amd64 /bin/gosu

#ADD https://github.com/tianon/gosu/releases/download/$gosu_ver/gosu-amd64 /bin/gosu

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN mkdir /docker-entrypoint-initdb.d

COPY entrypoint.sh /entrypoint.sh
COPY config.xml /etc/clickhouse-server/config.xml

RUN chmod +x \
    /entrypoint.sh \
    /bin/gosu

RUN /usr/bin/fromdos /entrypoint.sh \
    && mkdir ${CLICKHOUSE_SERVER_HOME} /mnt/sharedb \
    && userdel -r "clickhouse" \
    && chmod ug+rw /etc/passwd \
    && echo '#!/bin/bash' > /usr/local/bin/fix-username-and-start.sh \
    && echo 'echo "clickhouse:x:$(id -u):$(id -g)::${CLICKHOUSE_SERVER_HOME}:/bin/bash" >> /etc/passwd' >> /usr/local/bin/fix-username-and-start.sh \
    && echo '. /entrypoint.sh' >> /usr/local/bin/fix-username-and-start.sh \
    && chgrp root /usr/local/bin/fix-username-and-start.sh \
    && chmod 774 /usr/local/bin/fix-username-and-start.sh \
    && chown -R 1001:1001 /opt/ /mnt/sharedb/ \
    && chgrp -R 0 /run && chmod -R g=u /run \
    && chgrp -R 0 ${CLICKHOUSE_SERVER_HOME} /mnt/sharedb && chmod -R g=u ${CLICKHOUSE_SERVER_HOME} && chmod -R ugo+rw /mnt/sharedb


EXPOSE 9000 8123 9009

USER 1001
CMD ["/usr/local/bin/fix-username-and-start.sh"]

