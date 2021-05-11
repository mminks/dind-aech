#!/usr/bin/env sh

set -eo pipefail

COMPOSE_FILE=${1?"Missing docker compose file name. Usage: deploy_to_docker.sh '<compose_file>' '<user@host>' '[/path/to/aws/ssm]'"}
TARGET=${2?"Missing deploy server. Usage: deploy_to_docker.sh '<compose_file>' '<user@host>' '[/path/to/aws/ssm]'"}
ENV_PATH=${3}

if [ ! -r "${COMPOSE_FILE}" ]; then
    echo "${COMPOSE_FILE} not found or readable!" >&2
    exit 1
fi

BASE_NAME=$(basename ${COMPOSE_FILE})
PROJECT_NAME=${BASE_NAME%.*}

if [ "${PROJECT_NAME}" = "docker-compose" ]; then
    echo "${COMPOSE_FILE}
    " >&2
    exit 1
fi

USER="$(echo ${TARGET} | cut -d@ -f1)"
HOST="$(echo ${TARGET} | cut -d@ -f2)"

if [ -z "${USER}" ] || [ -z "${HOST}" ] || [ "${USER}" = "${HOST}" ]; then
    echo "Deploy server needs to be user@host" >&2
    exit 1
fi

# ${HOST} might be dns load balanced. To make sure we always get the same machine
# we resolve the ip once and use the ip from now on
IP="$(dig ${HOST} A +short | head -n 1)"

# Create directory on target machine
DEPLOY_FILE="deployments/$(basename ${COMPOSE_FILE})"
ssh "${USER}@${IP}" "mkdir --parents $(dirname ${DEPLOY_FILE})"

# Copy compose file to target server and replace all variables
cat "${COMPOSE_FILE}" | envsubst | ssh "${USER}@${IP}" "cat > ${DEPLOY_FILE}"

# Start the deployment
ssh "${USER}@${IP}" /bin/bash <<EOF

    set -eo pipefail

    # get secrets from SSM if we are suppose to
    [[ -n "${ENV_PATH}" ]] && eval \$(AWS_REGION=${AWS_DEFAULT_REGION} AWS_ENV_PATH=${ENV_PATH} /usr/local/bin/aws-env)

    # deploy the stack
    docker-compose --file ${DEPLOY_FILE} --project-name ${PROJECT_NAME} up --detach --no-color

EOF
