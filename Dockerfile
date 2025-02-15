FROM golang:1 AS build

ARG VERSION="1.7.1"
ARG CHECKSUM="766455a8beb6728da1a0f9dfa9368badddd282db51c7abae5fa99c82bfb53882"

ADD https://github.com/coredns/coredns/archive/v$VERSION.tar.gz /tmp/coredns.tar.gz
ADD plugin.cfg /tmp/plugin.cfg

RUN [ "$CHECKSUM" = "$(sha256sum /tmp/coredns.tar.gz | awk '{print $1}')" ] && \
    tar -C /tmp -xf /tmp/coredns.tar.gz && \
    apt update && \
    apt install -y ca-certificates && \
    cd /tmp/coredns-$VERSION && \
    cp /tmp/plugin.cfg /tmp/coredns-$VERSION/plugin.cfg && \
      make

RUN mkdir -p /rootfs/etc/ssl/certs && \
    cp /tmp/coredns-$VERSION/coredns /rootfs/ && \
    echo "nogroup:*:100:nobody" > /rootfs/etc/group && \
    echo "nobody:*:100:100:::" > /rootfs/etc/passwd && \
    cp /etc/ssl/certs/ca-certificates.crt /rootfs/etc/ssl/certs/


FROM scratch

COPY --from=build --chown=100:100 /rootfs /

USER 100:100
ENTRYPOINT ["/coredns"]