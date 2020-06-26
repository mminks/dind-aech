#!/usr/bin/env sh

set -e

MANIFEST=${1?"Please specify the manifest files or directory you want to deploy to kubernetes"}
DEPLOYMENT_NAME=${2}
ENV_PATH=${3}

if [ -d "${MANIFEST}" ]; then
  MANIFEST="${MANIFEST}/*"
fi

# get secrets from SSM if we are suppose to
[ -n "${ENV_PATH}" ] && eval "$(AWS_REGION=${AWS_DEFAULT_REGION} AWS_ENV_PATH=${ENV_PATH} /usr/local/bin/aws-env)"

echo "Starting deployment..."

cat ${MANIFEST} | envsubst | kubectl apply -f -

if [ -n "${DEPLOYMENT_NAME}" ]; then
  echo "Watching deployment status..."

  kubectl -n "${NAMESPACE:-default}" rollout status "${DEPLOYMENT_NAME}"
fi
