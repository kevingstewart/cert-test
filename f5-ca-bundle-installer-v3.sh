#!/bin/bash
## Author: kevin-at-f5-dot-com
## Version: 20251216-2
## Installs a new curated F5 CA bundle on the BIG-IP

BUNDLE_NAME="f5-ca-bundle-new.crt"
CERT_URL="https://raw.githubusercontent.com/kevingstewart/cert-test/refs/heads/main/updated-ca-bundle.crt"
HASH=5a062aa2c73be246f650dd0a48554a8beecc0ad1623d89132c132ba7585f0384

## Reporting function
report() {
    local interact="${1}"
    local message="${2}"

    if [ "${interact}" == 1 ]; then
        echo -e "${message}"
    else
        logger -p local0.info "F5 CA Bundle Update Script: ${message}"
    fi
}

## Test for interactive shell
if [ -t 0 ]; then interactive=1; else interactive=0; fi

## Ask interactive user for option to update existing CA Bundle Mgr objects (bypass for non-interactive/BIG-IQ script run)
if [ "${interactive}" == 1 ]; then
    ## Ask user if they want the script to update any ca-bundle-manager objects using the old bundle
    answer=false && found=false
    echo -e "Do you wish for this script to adjust any CA Bundle Manager objects using the old F5 CA bundle?"
    echo -e "Note: the default 'ca-bundle.crt' object cannot be modified."
    while true; do
        read -p "Type 'yes', 'no', or 'q' to quit: " yn
        case $yn in
            yes ) answer=true; break;;
            no ) answer=false; break;;
            q ) answer=false; exit;;
        esac
    done
else
    answer=true
    found=false
fi

## Echo/log start of script
report "${interactive}" "Starting"

## Fetch the new CA bundle file and store locally for validation testing
curl -s "${CERT_URL}" -o "${BUNDLE_NAME}"

## TEST: Count the number of certs in the bundle. Verify that at least one certificate exists in the bundle, exit on validation failure
certcount=$(grep -e "-----BEGIN CERTIFICATE-----" "${BUNDLE_NAME}" | wc -l)
if [ "$certcount" == 0 ]; then report "${interactive}" "CA bundle download failed, halting" && rm -f "$(pwd)/${BUNDLE_NAME}" && exit 1; fi

## TEST: Calculate SHA256 hash on the downloaded CA bundle, exit on validation failure
echo "${HASH} ${BUNDLE_NAME}" | sha256sum --check --status
if [ $? -ne 0 ]; then report "${interactive}" "Checksum failed, halting" && rm -f "$(pwd)/${BUNDLE_NAME}" && exit 1; fi

## Loop through and verify all certs in the bundle, exit on any validation failures
for index in $(seq 1 ${certcount}); do
    ## Separate each certificate
    tmpcert=$(awk "/-----BEGIN CERTIFICATE-----/{i++}i==$index" "${BUNDLE_NAME}")
    
    ## TEST: Run openssl x509 on each certificate to get details, also checking for parsing errors. Exit on validation failures
    certdata=$(echo "$tmpcert" | openssl x509 -noout -subject -issuer -enddate 2>&1)
    if [ $? -ne 0 ]; then report "${interactive}" "Found certificate error, halting" && rm -f "$(pwd)/${BUNDLE_NAME}" && exit 1; fi
done
      
## Validation tests passed: Create/update f5-ca-bundle-new
tmsh install sys crypto cert ${BUNDLE_NAME} from-local-file "$(pwd)/${BUNDLE_NAME}"

## If user opts to update CA bundle mgr objects, loop through ca-bundle-manager objects and replace the trusted-ca-bundle if using the old bundle
if [[ "$answer" == "true" ]]; then
    for p in $(tmsh list sys crypto ca-bundle-manager | egrep '^sys' | awk -F" " '{print $4}'); do 
        if [[ "$p" != "ca-bundle" && "$(tmsh list sys crypto ca-bundle-manager ${p} one-line)" =~ "f5-ca-bundle.crt" ]]; then
            report "${interactive}" "$p contains old f5-ca-bundle"
            found=true
            tmsh modify sys crypto ca-bundle-manager ${p} trusted-ca-bundle ${BUNDLE_NAME}
        fi
    done
    if [[ "$found" == "false" ]]; then
        report "${interactive}" "No CA bundle manager objects are using the old F5 CA bundle"
    fi
fi

## Clean up local files, echo/log end of script
rm -f "$(pwd)/${BUNDLE_NAME}"
report "${interactive}" "Complete"
exit 0
