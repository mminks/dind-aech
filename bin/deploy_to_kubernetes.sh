#!/usr/bin/env sh

set -eo pipefail

MANIFEST=${1?"Please specify the manifest files or directory you want to dpeloy to kubernetes"}
DEPLOYMENT_NAME=${2}

if [ -d "${MANIFEST}" ]; then
    MANIFEST="${MANIFEST}/*"
fi

echo "Starting deployment"
cat ${MANIFEST} | envsubst | kubectl apply -f -

if [ -n "${DEPLOYMENT_NAME}" ]; then
    echo "Watch deployment status"
    kubectl rollout status "${DEPLOYMENT_NAME}"
fi
