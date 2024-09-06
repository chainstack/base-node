FROM ghcr.io/base-org/node:v0.10.2

USER root

RUN apt-get update && \
    apt-get install -y curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
