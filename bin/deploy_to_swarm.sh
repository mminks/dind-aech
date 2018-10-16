#!/usr/bin/env sh

set -exo pipefail

APP=${1?"Missing app name. Usage: deploy_to_swarm.sh '<app_name>' '<user@host>' '[/path/to/aws/ssm]'"}
TARGET=${2?"Missing deploy server. Usage: deploy_to_swarm.sh '<app_name>' '<user@host>' '[/path/to/aws/ssm]'"}
ENV_PATH=${3}

STACK_FILE="swarm/${APP}.yml"

if [ ! -f "${STACK_FILE}" ]; then
    echo "${STACK_FILE} not found" >&2
    exit 1
fi

USER="$(echo $TARGET | cut -d@ -f1)"
HOST="$(echo $TARGET | cut -d@ -f2)"

if [ -z "${USER}" ] || [ -z "${HOST}" ] || [ "${USER}" == "${HOST}" ]; then
    echo "Deploy server needs to be user@host" >&2
    exit 1
fi

# ${HOST} might be dns load balanced. To make sure we always get the same machine
# we resolve the ip once and use the ip from now on
IP="$(dig ${HOST} A +short | head --lines=1)"

# Copy swarm file to target server and replace all variables
ssh "${USER}@${IP}" "mkdir --parents ~/deployments"
cat "${STACK_FILE}" | envsubst | ssh "${USER}@${IP}" "cat > deployments/${APP}.yml"

ssh "${USER}@${IP}" /bin/bash <<EOF

    set -eo pipefail

    # get secrets from SSM if we are suppose to
    [[ -n "${ENV_PATH}" ]] && eval \$(AWS_REGION=${AWS_DEFAULT_REGION} AWS_ENV_PATH=${ENV_PATH} /usr/local/bin/aws-env)

    # load cluster_name into environment if it exists
    [[ -r "/etc/cluster_name" ]] && export CLUSTER_NAME=\$(cat /etc/cluster_name)

    # deploy the stack to swarm
    docker stack deploy --prune --with-registry-auth --compose-file deployments/${APP}.yml ${APP}

    # check for succesfull deployment
    SECONDS=0
    STATE="UNKNOWN"
    until [ "\${STATE}" == "Running" ]; do
        STATE="\$(docker stack ps ${APP} --no-trunc --format '{{ json . }}' | jq --slurp --raw-output '.[0].CurrentState' | awk '{print \$1;}')"
        echo "Wait for deployment to finish. Current state is **\${STATE}**"
        sleep 1
        if [ "\${SECONDS}" -gt "60" ]; then
            echo "Deployment took too long" >&2
            echo "Error: \$(docker stack ps ${APP} --no-trunc --format '{{ json . }}' | jq --slurp --raw-output '.[0].Error')"
            exit 1
        fi
    done

EOF
