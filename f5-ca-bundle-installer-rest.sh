#!/bin/bash

BIGIP="10.1.1.6"
BUNDLE_NAME="f5-ca-bundle-new.crt"
CERT_URL="https://raw.githubusercontent.com/kevingstewart/cert-test/refs/heads/main/updated-ca-bundle.crt"


## Ensure that user:pass is available for iControl
if [[ -z "${BIGUSER}" ]]
then
    echo 
    echo "The user:pass must be set in an environment variable. Exiting."
    echo "   export BIGUSER='admin:password'"
    echo 
    exit 1
fi

## Create the new curated F5 CA bundle
data="{\"command\": \"install\", \"name\": \"${BUNDLE_NAME}\", \"from-url\": \"${CERT_URL}\"}"
echo $data
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-X POST \
-d "${data}" \
https://10.1.1.6/mgmt/tm/sys/crypto/cert
