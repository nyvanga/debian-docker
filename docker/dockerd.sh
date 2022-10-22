#!/bin/bash


function launch_dockerd() {
    /usr/bin/dockerd \
        --host=unix:///var/run/docker.sock \
        --host=tcp://0.0.0.0:2376 \
        --tlsverify \
        --tlscacert "/usr/local/share/ca-certificates/docker.crt" \
        --tlscert "/usr/local/share/certificates/localhost.crt" \
        --tlskey "/usr/local/share/certificates/localhost.key"        
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
    echo -e "\e[32mINFO\e[0m: Dockerd launched successfully!"
}

if [[ "$@" == "" ]]; then
    echo -e "\e[32mINFO\e[0m: Launching dockerd (daemon)"
    launch_dockerd
else
    echo -e "\e[32mINFO\e[0m: Launching dockerd (in background)"
    launch_dockerd &>/var/log/docker.log &
    check_dockerd_launched
    echo -e "\e[32mINFO\e[0m: Running command '$@'"
    "$@"
fi
