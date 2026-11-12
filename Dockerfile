# syntax=docker/dockerfile:1

FROM golang:1.21-bookworm AS builder
WORKDIR /src

COPY web/go.mod web/go.sum ./web/
RUN cd web && go mod download

COPY web ./web
RUN cd web && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/nftnode-panel .

FROM debian:bookworm-slim

ARG VERSION=dev
LABEL org.opencontainers.image.title="nftnode" \
      org.opencontainers.image.description="nftnode forwarding management panel" \
      org.opencontainers.image.version="${VERSION}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl iproute2 nftables procps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /app/data /etc/nft-forward /etc/realm /etc/xray /var/log/nftnode

WORKDIR /app
COPY --from=builder /out/nftnode-panel /usr/local/bin/nftnode-panel
COPY web/config.toml.example /app/config.toml.example

ENV TZ=UTC
EXPOSE 3456
VOLUME ["/app/data", "/etc/nft-forward"]

ENTRYPOINT ["/usr/local/bin/nftnode-panel"]
