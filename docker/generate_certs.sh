#!/bin/bash

CA_KEY_FILE=docker.key
CA_CERT_FILE=docker.crt

KEY_FILE=localhost.key
CONF_FILE=localhost.conf
CSR_FILE=localhost.csr
CRT_FILE=localhost.crt

openssl genrsa -out ${CA_KEY_FILE} 4096

openssl req -new -key ${CA_KEY_FILE} -x509 -days 3650 -out ${CA_CERT_FILE} -subj "/CN=Docker-in-Debian"

openssl genrsa -out ${KEY_FILE} 4096

cat << EOF > ${CONF_FILE}
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
IP.1 = 127.0.0.1

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF

openssl req -new -key ${KEY_FILE} -out ${CSR_FILE} -config ${CONF_FILE}

openssl x509 -req -in ${CSR_FILE} \
	-CA ${CA_CERT_FILE} -CAkey ${CA_KEY_FILE} -CAcreateserial \
	-out ${CRT_FILE} -days 3650 -extensions v3_ext -extfile ${CONF_FILE}

rm ${CA_KEY_FILE} ${CONF_FILE} ${CSR_FILE}