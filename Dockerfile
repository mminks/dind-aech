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
    && TERRAFORM_LEGACY_URL=$(curl -Ls https://releases.hashicorp.com/terraform/index.json \
                        | jq '.' \
                        | awk '{print $2}' \
                        | grep -v alpha \
                        | grep -v beta \
                        | grep https \
                        | grep linux \
                        | grep amd64 \
                        | grep -E "0\.11\.[0-9]+\/" \
                        | tr -d '"' \
                        | sort -V \
                        | tail -n1) \
    && TERRAFORM_URL=$(curl -Ls https://releases.hashicorp.com/terraform/index.json \
                        | jq '.' \
                        | awk '{print $2}' \
                        | grep -v alpha \
                        | grep -v beta \
                        | grep https \
                        | grep linux \
                        | grep amd64 \
                        | tr -d '"' \
                        | sort -V \
                        | tail -n1) \
    && wget --output-document=/tmp/terraform_legacy.zip ${TERRAFORM_LEGACY_URL} \
    && wget --output-document=/tmp/terraform.zip ${TERRAFORM_URL} \
    && unzip /tmp/terraform_legacy.zip -d /tmp \
    && mv /tmp/terraform /usr/local/bin/terraform0.11 \
    && unzip /tmp/terraform.zip -d /tmp \
    && mv /tmp/terraform /usr/local/bin/terraform

FROM docker:stable-dind

WORKDIR /root

COPY bin/* /usr/local/bin/
COPY ssh/config /root/.ssh/

COPY --from=ecr-login /root/go/bin/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login
COPY --from=ecr-login /usr/bin/envsubst /usr/local/bin/envsubst
COPY --from=terraform /usr/local/bin/terraform0.11 /usr/local/bin/terraform0.11
COPY --from=terraform /usr/local/bin/terraform /usr/local/bin/terraform

RUN set -exo pipefail \
    && apk add --no-cache \
        bind-tools \
        coreutils \
        git \
        jq \
        libintl \
        openssh-client \
        openssl \
        python3 \
        curl \
        python3-dev  \
        py-pip \
        musl-dev \
        gcc \
        make \
        libffi-dev \
        openssl-dev \
    # setup ecr-login
    && mkdir -p /root/.docker \
    && echo "{ \"credsStore\": \"ecr-login\" }" > /root/.docker/config.json \
    # install awscli
    && wget --output-document=/tmp/awscli-bundle.zip \
         "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" \
    && unzip /tmp/awscli-bundle.zip -d /tmp \
    && /usr/bin/python3 /tmp/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
    # upgrade pip
    && pip3 install --upgrade pip \
    # install docker-compose
    && pip3 install docker-compose \
    # install kubectl
    && wget --output-document=/usr/local/bin/kubectl \
         https://storage.googleapis.com/kubernetes-release/release/$(wget --quiet --output-document=- https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && mkdir -p ~/.kube \
    # cleanup
    && rm -rf /tmp/awscli-bundle* \
    && rm -rf /var/cache/apk/* \
    # show versions of installed packages
    && aws --version \
    && terraform version \
    && kubectl version --client=true --short=true
