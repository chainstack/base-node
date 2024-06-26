FROM golang:1.21 as op

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/optimism.git
ENV VERSION=v1.7.6
# for verification:
ENV COMMIT=4a487b8920daa9dc4b496d691d5f283f9bb659b1

RUN git clone $REPO --branch op-node/$VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN cd op-node && \
    make VERSION=$VERSION op-node

FROM golang:1.21 as geth

WORKDIR /app

ENV REPO=https://github.com/ethereum-optimism/op-geth.git
ENV VERSION=v1.101315.1
# for verification:
ENV COMMIT=3fbae78d638d1b903e702a14f98644c1103ae1b3

# avoid depth=1, so the geth build can read tags
RUN git clone $REPO --branch $VERSION --single-branch . && \
    git switch -c branch-$VERSION && \
    bash -c '[ "$(git rev-parse HEAD)" = "$COMMIT" ]'

RUN go run build/ci.go install -static ./cmd/geth

FROM golang:1.21

RUN apt-get update && \
    apt-get install -y jq curl supervisor && \
    rm -rf /var/lib/apt/lists
RUN mkdir -p /var/log/supervisor

WORKDIR /app

COPY --from=op /app/op-node/bin/op-node ./
COPY --from=geth /app/build/bin/geth ./
RUN cd /etc/supervisor/conf.d/ && wget https://raw.githubusercontent.com/base-org/node/main/supervisord.conf
RUN wget https://raw.githubusercontent.com/base-org/node/main/geth-entrypoint
RUN wget https://raw.githubusercontent.com/base-org/node/main/op-node-entrypoint
RUN mkdir mainnet sepolia
RUN cd mainnet && wget https://raw.githubusercontent.com/base-org/node/main/mainnet/genesis-l2.json && wget https://raw.githubusercontent.com/base-org/node/main/mainnet/rollup.json
RUN cd sepolia && wget https://raw.githubusercontent.com/base-org/node/main/sepolia/rollup.json && wget https://raw.githubusercontent.com/base-org/node/main/sepolia/genesis-l2.json
CMD ["/usr/bin/supervisord"]

