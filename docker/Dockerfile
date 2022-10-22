ARG BASE_IMAGE

FROM ${BASE_IMAGE}
MAINTAINER Anders Nyvang

ENV TZ=Europe/Copenhagen
ENV LANG C.UTF-8

WORKDIR /work

COPY certs/ca/docker.crt /usr/local/share/ca-certificates/docker.crt
COPY certs/localhost.key /usr/local/share/certificates/localhost.key
COPY certs/localhost.crt /usr/local/share/certificates/localhost.crt

COPY docker.gpg /etc/apt/trusted.gpg.d/docker.gpg

RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
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
    update-ca-certificates && \
    echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install --quiet 2 --no-install-recommends \
        docker-ce \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY dockerd.sh /usr/local/bin/

ENTRYPOINT ["dockerd.sh"]