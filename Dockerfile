# Stage 1: Build Zoekt
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache ca-certificates git

WORKDIR /go/src/github.com/sourcegraph/zoekt

RUN go install github.com/sourcegraph/zoekt/cmd/...@latest

# Stage 2: Runtime Environment
FROM alpine:3.21

# Install runtime dependencies
RUN apk add --no-cache \
    git \
    ca-certificates \
    bind-tools \
    tini \
    jansson \
    wget \
    bash

# Install universal-ctags
COPY install-ctags-alpine.sh /usr/local/bin/install-ctags-alpine.sh
RUN chmod +x /usr/local/bin/install-ctags-alpine.sh && /usr/local/bin/install-ctags-alpine.sh && rm /usr/local/bin/install-ctags-alpine.sh

# Copy Zoekt binaries from builder
COPY --from=builder /go/bin/* /usr/local/bin/

# Copy the indexer script
COPY indexer.sh /usr/local/bin/indexer.sh
RUN chmod +x /usr/local/bin/indexer.sh

# Environment and Volume setup
ENV INDEX_DIR=/data/index
ENV REPOS_DIR=/data/repos
ENV ZOEKT_INTERVAL=3600

WORKDIR /data
VOLUME ["/data/index", "/data/repos"]

# Default entrypoint (using tini for signal handling)
ENTRYPOINT ["/sbin/tini", "--"]

# Default command (overridden in compose/ctl)
CMD ["zoekt-webserver", "-index", "/data/index", "-listen", ":6070"]
