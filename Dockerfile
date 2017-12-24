FROM docker:stable-dind

# install amazon ECR docker credential helper
RUN apk add --update ca-certificates openssl git make go gcc libc-dev jq curl coreutils python
RUN update-ca-certificates
RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login
RUN mv /root/go/bin/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login
RUN rm -Rf /root/go

RUN mkdir -p /root/.docker
COPY config.json /root/.docker/config.json

# install latest terraform
RUN wget $(curl -Ls https://releases.hashicorp.com/index.json | jq '{terraform}' | grep url | egrep linux_amd64 | sort -V | tail -n1 | awk '{print $2}' | sed 's/"*,*//g') -O /tmp/terraform.zip
RUN unzip /tmp/terraform.zip -d /usr/local/bin
RUN rm -Rf /tmp/terraform.zip

# print terraform version
RUN terraform version

# install AWS cli
RUN curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python get-pip.py
RUN pip install awscli

# print aws cli version
RUN aws --version

# cleanup
RUN apk del make go gcc libc-dev jq curl coreutils \
    && rm -rf /var/cache/apk/*
