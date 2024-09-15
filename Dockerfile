# syntax=docker/dockerfile:labs
FROM alpine:3.20.3 AS build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG VALKEY_VERSION=8.0.0-rc2

RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates git build-base pkgconf && \
    git clone --recursive --branch "$VALKEY_VERSION" https://github.com/valkey-io/valkey /src && \
    cd /src && \
    sed -i "s|\(protected_mode.*\)1|\10|g" /src/src/config.c && \
    make -j "$(nproc)" LDFLAGS="-s -w -static" CFLAGS="-static" USE_SYSTEMD=no BUILD_TLS=no

FROM alpine:3.20.3
COPY --from=build /src/src/valkey-cli    /usr/local/bin/valkey-cli
COPY --from=build /src/src/valkey-server /usr/local/bin/valkey-server
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates tzdata tini && \
    valkey-cli --version && \
    valkey-server --version && \
    addgroup -S -g 1000 redis && \
    adduser -S -G redis -u 999 redis && \
    mkdir /data && chown redis:redis /data && \
    ln -s /usr/local/bin/valkey-cli /usr/local/bin/redis-cli && \
    ln -s /usr/local/bin/valkey-server /usr/local/bin/redis-server

VOLUME /data
WORKDIR /data
USER redis:redis

ENTRYPOINT ["tini", "--", "valkey-server"]
HEALTHCHECK CMD redis-cli ping
EXPOSE 6379/tcp
