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
    && TERRAFORM_VERSION_old=0.11.14 \
    && TERRAFORM_VERSION_new=0.12.5 \
    && wget --output-document=/tmp/terraform_${TERRAFORM_VERSION_old}.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION_old}/terraform_${TERRAFORM_VERSION_old}_linux_amd64.zip" \
    && wget --output-document=/tmp/terraform_${TERRAFORM_VERSION_new}.zip \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION_new}/terraform_${TERRAFORM_VERSION_new}_linux_amd64.zip" \
    && mkdir /opt/terraform_${TERRAFORM_VERSION_old} \
    && mkdir /opt/terraform_${TERRAFORM_VERSION_new} \
    && unzip /tmp/terraform_${TERRAFORM_VERSION_old}.zip -d /opt/terraform_${TERRAFORM_VERSION_old} \
    && unzip /tmp/terraform_${TERRAFORM_VERSION_new}.zip -d /opt/terraform_${TERRAFORM_VERSION_new}

FROM docker:stable-dind

WORKDIR /root
ENV PATH /opt/terraform_0.11.14:${PATH}

COPY bin/* /usr/local/bin/
COPY ssh/config /root/.ssh/

COPY --from=ecr-login /root/go/bin/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login
COPY --from=ecr-login /usr/bin/envsubst /usr/local/bin/envsubst
COPY --from=terraform /opt /opt

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
