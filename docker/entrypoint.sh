#!/bin/bash

set -e

CA_CERT_FILE="${VOLUME_CERTS}/docker-ca.crt"
KEY_FILE="${VOLUME_CERTS}/docker-localhost.key"
CRT_FILE="${VOLUME_CERTS}/docker-localhost.crt"

function create_certs() {
    echo -e "\e[32mINFO\e[0m: Creating certificates (CA)"
    local ca_key_file="/root/docker-ca.key"
    openssl genrsa -out ${ca_key_file} 4096
    openssl req -new -key ${ca_key_file} -x509 -days 365 -out ${CA_CERT_FILE} -subj "/CN=Docker-in-Debian (CA)"
    cp ${CA_CERT_FILE} /usr/local/share/ca-certificates/docker-ca.crt
    update-ca-certificates
    echo -e "\e[32mINFO\e[0m: Creating certificates (localhost)"
    local conf_file="/root/docker-localhost.conf"
    local csr_file="/root/docker-localhost.csr"
    openssl genrsa -out ${KEY_FILE} 4096
    cat << EOF > ${conf_file}
[ req ]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
CN = "localhost"

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
DNS.2 = docker
IP.1 = 127.0.0.1

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF
    openssl req -new -key ${KEY_FILE} -out ${csr_file} -config ${conf_file}
    openssl x509 -req -in ${csr_file} \
        -CA ${CA_CERT_FILE} -CAkey ${ca_key_file} -CAcreateserial \
        -out ${CRT_FILE} -days 365 -extensions v3_ext -extfile ${conf_file}
    rm ${ca_key_file} ${conf_file} ${csr_file}
    openssl verify -CAfile ${CA_CERT_FILE} ${CRT_FILE}
}

function launch_dockerd() {
    /usr/bin/dockerd \
        --host=unix:///var/run/docker.sock \
        --host=tcp://0.0.0.0:2376 \
        --tlsverify \
        --tlscacert "${CA_CERT_FILE}" \
        --tlskey "${KEY_FILE}" \
        --tlscert "${CRT_FILE}"
}

function check_dockerd_launched() {
    local sleep=5
    local tries=0
    local max_tries=3
    until docker info >/dev/null 2>&1; do
        if [ "${tries}" -gt "${max_tries}" ]; then
                cat /var/log/docker.log
                echo -e '\e[31mERROR\e[0m: Timed out trying to connect to internal docker host'
                exit 1
        fi
        tries=$(( ${tries} + 1 ))
        echo -e "\e[33mWARN\e[0m: Dockerd not launched yet. Checking again in \e[36m${sleep}\e[0m seconds..."
        sleep ${sleep}
    done
}

function add_user() {
    echo -e "\e[32mINFO\e[0m: Adding user (${USER_ID}:${GROUP_ID})"
    groupadd --gid ${GROUP_ID} work
    useradd --home-dir /work --gid work --groups docker --uid ${USER_ID} work
}

create_certs
if [[ "$@" == "" ]]; then
    echo -e "\e[32mINFO\e[0m: Launching dockerd (daemon)"
    launch_dockerd
else
    echo -e "\e[32mINFO\e[0m: Launching dockerd (in background)"
    launch_dockerd &>/var/log/docker.log &
    check_dockerd_launched
    if [[ -n ${USER_ID} ]] && [[ -n ${GROUP_ID} ]]; then
        add_user
        echo -e "\e[32mINFO\e[0m: Running command as (${USER_ID}:${GROUP_ID}) '$@'"
        su work -c "$(echo "$@")"
    else 
        echo -e "\e[32mINFO\e[0m: Running command '$@'"
        "$@"
    fi
fi
