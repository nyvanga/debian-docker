ARG BASE_IMAGE

FROM ${BASE_IMAGE}
MAINTAINER Anders Nyvang

ENV TZ=Europe/Copenhagen
ENV LANG=C.UTF-8
ENV VOLUME_CERTS=/certs

VOLUME ${VOLUME_CERTS}
VOLUME /var/lib/docker

WORKDIR /work

COPY key/docker.gpg /etc/apt/trusted.gpg.d/docker.gpg

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -qq && \
    apt-get install -qq --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        tzdata \
        curl \
        jq \
        openssh-client \
        unzip \
        git \
        gnupg \
        && \
    echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install --quiet 2 --no-install-recommends \
        docker-ce \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]