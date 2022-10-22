ARG FROM_IMAGE

FROM ${FROM_IMAGE}
MAINTAINER Anders Nyvang

ARG OPENJDK_VERSION=NO-VERSION

RUN apt-get update && \
    apt-get install --quiet 2 --no-install-recommends \
        openjdk-${OPENJDK_VERSION}-jre-headless \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
