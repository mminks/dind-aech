#!/usr/bin/env sh

set -eo pipefail

APP=${1?"Missing app name"}
SERVER=${2?"Missing target deploy server 'user@host'"}
ENV_PATH=${3}

STACK_FILE="swarm/${APP}.yml"

if [ ! -f "${STACK_FILE}" ]; then
    echo "${STACK_FILE} not found" >&2
    exit 1
fi

# Copy swarm file to target server and replace all variables
cat "${STACK_FILE}" | envsubst | ssh "${SERVER}" "cat > ${APP}.yml"

ssh "${SERVER}" /bin/bash <<EOF

    set -eo pipefail

    [[ -n "${ENV_PATH}" ]] && eval \$(AWS_REGION=${AWS_DEFAULT_REGION} AWS_ENV_PATH=${ENV_PATH} /usr/local/bin/aws-env)

    docker stack deploy --prune --with-registry-auth --compose-file ${APP}.yml ${APP}

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
