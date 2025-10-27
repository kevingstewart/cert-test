#!/bin/bash
## Author: kevin-at-f5-dot-com
## Version: 20251014-1
## Installs a new curated F5 CA bundle on the BIG-IP


BUNDLE_NAME="f5-ca-bundle-new.crt"
CERT_URL="https://raw.githubusercontent.com/kevingstewart/cert-test/refs/heads/main/updated-ca-bundle.crt"


## Create/update f5-ca-bundle-new
tmsh install sys crypto cert ${BUNDLE_NAME} from-url "${CERT_URL}"

## Ask user if they want the script to update any ca-bundle-manager objects using the old bundle
echo -e "\nNew Curated F5 CA bundle installed.\n"
answer=false && found=false
echo -e "Do you wish for this script to adjust any CA Bundle Manager objects using the old F5 CA bundle?\n"
while true; do
    read -p "Type 'yes', 'no', or 'q' to quit: " yn
    case $yn in
        yes ) answer=true; break;;
        no ) answer=false; break;;
        q ) answer=false; exit;;
    esac
done

## If yes, loop through ca-bundle-manager objects and replace the trusted-ca-bundle if using the old bundle
if [[ "$answer" == "true" ]]; then
    for p in $(tmsh list sys crypto ca-bundle-manager | egrep '^sys' | awk -F" " '{print $4}'); do 
        if [[ "$p" != "ca-bundle" && "$(tmsh list sys crypto ca-bundle-manager ${p} one-line)" =~ "f5-ca-bundle.crt" ]]; then
            echo "$p contains old f5-ca-bundle"
            found=true
            tmsh modify sys crypto ca-bundle-manager ${p} trusted-ca-bundle ${BUNDLE_NAME}
        fi
    done
    if [[ "$found" == "false" ]]; then
        echo -e "No CA bundle manager objects are using the old F5 CA bundle\n\n"
    fi
fi
