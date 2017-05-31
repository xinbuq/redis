FROM centos:7.2.1511
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
ENV GOSU_VERSION 1.7
RUN set -x \
    && groupadd -r redis \
    && useradd -r -g redis redis \
    && yum install -y epel-release ca-certificates wget \
    && yum install -y gcc libc6-dev make \
# grab gosu for easy step-down from root
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && mkdir -p /usr/src/redis

ADD .  /usr/src/redis/
RUN make -C /usr/src/redis \
	&& make -C /usr/src/redis install \
	&& rm -r /usr/src/redis \
	&& yum -y clean all \
    && mkdir /data  \
    && chown redis:redis /data

VOLUME /data
WORKDIR /data

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 6379
CMD [ "redis-server" ]
