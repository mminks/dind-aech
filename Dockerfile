FROM docker:stable-dind as ecr-login
RUN set -exo pipefail \
    && apk add --no-cache \
        gettext \
        git \
        go \
        make \
        musl-dev \
    && go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login


FROM docker:stable-dind as terraform
RUN set -exo pipefail \
    && apk add --no-cache \
        curl \
        jq \
    && TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq --raw-output '.current_version') \
    && wget --output-document=/tmp/terraform.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip /tmp/terraform.zip -d /usr/local/bin


FROM docker:stable-dind
COPY --from=ecr-login /root/go/bin/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login
COPY --from=ecr-login /usr/bin/envsubst /usr/local/bin/envsubst
COPY --from=terraform /usr/local/bin/terraform /usr/local/bin/terraform
RUN set -exo pipefail \
    && apk add --no-cache \
        libintl \
        openssh-client \
        openssl \
        python3 \
    # Setup ecr-login
    && mkdir -p /root/.docker \
    && echo "{ \"credsStore\": \"ecr-login\" }" > /root/.docker/config.json \
    # Install aws
    && wget --output-document=/tmp/awscli-bundle.zip \
        "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" \
    && unzip /tmp/awscli-bundle.zip -d /tmp \
    && /usr/bin/python3 /tmp/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
    && rm -rf /tmp/awscli-bundle* \
    && rm -rf /var/cache/apk/* \
    && aws --version \
    && terraform version
