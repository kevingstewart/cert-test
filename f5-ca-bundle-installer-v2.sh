#!/bin/bash
## Author: kevin-at-f5-dot-com
## Version: 20251120-1
## Installs a new curated F5 CA bundle on the BIG-IP


BUNDLE_NAME="f5-ca-bundle-new.crt"
CERT_URL="https://raw.githubusercontent.com/kevingstewart/cert-test/refs/heads/main/updated-ca-bundle.crt"

## Test for interactive shell
if [ -t 0 ]; then interactive=1; else interactive=0; fi

## Echo/log start of script
if [ "${interactive}" == 1 ]; then
    echo "F5 CA Bundle Update Script: Starting"
else
    logger -p local0.info "F5 CA Bundle Update Script: Starting"
fi

## Create/update f5-ca-bundle-new
tmsh install sys crypto cert ${BUNDLE_NAME} from-url "${CERT_URL}"

## Test for interactive user (bypass for non-interactive/BIG-IQ script run)
if [ "${interactive}" == 1 ]; then
    ## Ask user if they want the script to update any ca-bundle-manager objects using the old bundle
    answer=false && found=false
    echo -e "Do you wish for this script to adjust any CA Bundle Manager objects using the old F5 CA bundle?"
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

## If yes, loop through ca-bundle-manager objects and replace the trusted-ca-bundle if using the old bundle
if [[ "$answer" == "true" ]]; then
    for p in $(tmsh list sys crypto ca-bundle-manager | egrep '^sys' | awk -F" " '{print $4}'); do 
        if [[ "$p" != "ca-bundle" && "$(tmsh list sys crypto ca-bundle-manager ${p} one-line)" =~ "f5-ca-bundle.crt" ]]; then
            if [ "${interactive}" == 1 ]; then
                echo "F5 CA Bundle Update Script: $p contains old f5-ca-bundle"
            else
                logger -p local0.info "F5 CA Bundle Update Script: $p contains old f5-ca-bundle"
            fi
            found=true
            tmsh modify sys crypto ca-bundle-manager ${p} trusted-ca-bundle ${BUNDLE_NAME}
        fi
    done
    if [[ "$found" == "false" ]]; then
        if [ "${interactive}" == 1 ]; then
            echo -e "F5 CA Bundle Update Script: No CA bundle manager objects are using the old F5 CA bundle"
        else
            logger -p local0.info "F5 CA Bundle Update Script: No CA bundle manager objects are using the old F5 CA bundle"
        fi
    fi
fi

## Echo/log end of script
if [ "${interactive}" == 1 ]; then
    echo "F5 CA Bundle Update Script: Complete"
else
    logger -p local0.info "F5 CA Bundle Update Script: Complete"
fi

exit 0
