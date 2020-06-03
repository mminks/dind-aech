#!/usr/bin/env sh

set -eo pipefail

MANIFEST=${1?"Please specify the manifest files or directory you want to deploy to kubernetes"}
DEPLOYMENT_NAME=${2}
NAMESPACE=${NAMESPACE:-default}

echo "Starting deployment..."

cat ${MANIFEST} | envsubst | kubectl apply -f -

if [ -n "${DEPLOYMENT_NAME}" ]; then
  echo "Watching deployment status..."

  kubectl -n ${NAMESPACE} rollout status "${DEPLOYMENT_NAME}"
fi
