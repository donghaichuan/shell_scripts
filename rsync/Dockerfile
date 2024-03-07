FROM alpine:3.18
MAINTAINER donghaichuan@tsingj.com

COPY rsyncd.conf /etc/
COPY docker-entrypoint.sh /

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk add rsync curl ca-certificates \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /data \
    && touch /var/log/rsync.log \
    && chmod +x /docker-entrypoint.sh

EXPOSE 873

ENTRYPOINT ["/docker-entrypoint.sh"]