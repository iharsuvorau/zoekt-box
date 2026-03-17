#!/bin/sh
# This script installs universal-ctags within an alpine container.

CTAGS_VERSION=v6.1.0
CTAGS_ARCHIVE_TOP_LEVEL_DIR=ctags-6.1.0

cleanup() {
  apk --no-cache --purge del ctags-build-deps || true
}

set -eux

apk --no-cache add \
  --virtual ctags-build-deps \
  autoconf \
  automake \
  binutils \
  curl \
  g++ \
  gcc \
  jansson-dev \
  make \
  pkgconfig

apk --no-cache add jansson

NUMCPUS=$(grep -c '^processor' /proc/cpuinfo)

mkdir -p /tmp/ctags
curl -L --retry 5 "https://github.com/universal-ctags/ctags/archive/refs/tags/$CTAGS_VERSION.tar.gz" | tar xz -C /tmp/ctags --strip-components=1
cd /tmp/ctags
./autogen.sh
./configure --program-prefix=universal- --enable-json
make -j"$NUMCPUS" --load-average="$NUMCPUS"
make install
cd /
rm -rf /tmp/ctags
cleanup
