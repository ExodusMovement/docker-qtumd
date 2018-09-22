FROM alpine:3.8 AS builder

ENV BUILD_TAG 0.16.1

RUN apk add --no-cache \
    autoconf \
    automake \
    db-dev \
    boost-dev \
    build-base \
    git \
    openssl-dev \
    libevent-dev \
    libtool \
    zeromq-dev

RUN git clone --recursive https://github.com/qtumproject/qtum.git
WORKDIR /qtum
RUN git checkout mainnet-ignition-v$BUILD_TAG

RUN ./autogen.sh
RUN ./configure \
  --disable-shared \
  --disable-static \
  --with-incompatible-bdb \
  # --disable-wallet \
  --disable-tests \
  --disable-bench \
  --enable-zmq \
  --with-utils \
  --without-libs \
  --without-gui
RUN make -j$(nproc)
RUN strip src/qtumd src/qtum-cli


FROM alpine:3.8

RUN apk add --no-cache \
  db-c++ \
  boost \
  boost-program_options \
  boost-random \
  openssl \
  libevent \
  zeromq

COPY --from=builder /qtum/src/qtumd /qtum/src/qtum-cli /usr/local/bin/

RUN addgroup -g 1000 qtumd \
  && adduser -u 1000 -G qtumd -s /bin/sh -D qtumd

USER qtumd

# P2P & RPC
EXPOSE 8333 8332

ENV \
  QTUMD_DBCACHE=450 \
  QTUMD_PAR=0 \
  QTUMD_PORT=8333 \
  QTUMD_RPC_PORT=8332 \
  QTUMD_RPC_THREADS=4 \
  QTUMD_ARGUMENTS=""

CMD exec qtumd \
  -dbcache=$QTUMD_DBCACHE \
  -par=$QTUMD_PAR \
  -port=$QTUMD_PORT \
  -rpcport=$QTUMD_RPC_PORT \
  -rpcthreads=$QTUMD_RPC_THREADS \
  $QTUMD_ARGUMENTS
