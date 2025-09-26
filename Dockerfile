# syntax=docker/dockerfile:labs
FROM alpine:3.22.1 AS build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG VALKEY_VERSION=8.1.3

ARG CC=clang
ARG CFLAGS="-O3"
ARG CXX=clang++
ARG CXXFLAGS="-O3"
ARG LDFLAGS="-s -static"

RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates git make clang pkgconf && \
    git clone --depth 1 https://github.com/valkey-io/valkey --branch "$VALKEY_VERSION" /src && \
    cd /src && \
    sed -i "s|\(protected_mode.*\)1|\10|g" /src/src/config.c && \
    make -j "$(nproc)"

FROM alpine:3.22.1
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
