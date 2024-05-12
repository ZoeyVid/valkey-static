# syntax=docker/dockerfile:labs
FROM alpine:3.19.1 as build
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
ARG VALKEY_VERSION=7.2.5

RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates git build-base && \
    git clone --recursive --branch "$VALKEY_VERSION" https://github.com/valkey-io/valkey /src && \
    cd /src && \
    make -j "$(nproc)" LDFLAGS="-s -w -static" CFLAGS="-static" USE_SYSTEMD=no BUILD_TLS=no

FROM alpine:3.19.1
COPY --from=build /src/src/valkey-server /usr/local/bin/valkey-server
RUN apk upgrade --no-cache -a && \
    apk add --no-cache ca-certificates tzdata tini && \
    valkey-server -v

ENTRYPOINT ["tini", "--", "valkey-server"]
CMD ["--loglevel", "notice"]
EXPOSE 6379/tcp
