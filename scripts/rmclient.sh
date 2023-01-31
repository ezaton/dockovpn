#!/bin/bash

source ./functions.sh

removeConfig "$@"

echo "removing certificate directory"
openssl verify -crl_check -CAfile ${APP_PERSIST_DIR}/clients/${@}/ca.crt -CRLfile /etc/openvpn/crl.pem  ${APP_PERSIST_DIR}/clients/${@}/${@}.crt 
RET=$?
if [[ ${RET} == 2 ]]; then
    echo "Certificate is in CRL. Removing directory if exists"
    rm -Rf ${APP_PERSIST_DIR}/clients/${@}
fi