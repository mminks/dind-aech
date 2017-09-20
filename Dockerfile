FROM docker:stable-dind

RUN mkdir -p /root/.docker
COPY config.json /root/.docker/config.json

RUN apk add --update ca-certificates openssl git make go gcc libc-dev jq curl
RUN update-ca-certificates
RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login
RUN mv /root/go/bin/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login
RUN rm -Rf /root/go

RUN wget $(curl -Ls https://releases.hashicorp.com/index.json | jq '{terraform}' | grep url | egrep linux_amd64 | sort -n -t'.' -k 3,1 -k4,1 | tail -n1 | awk '{print $2}' | sed 's/"//g') -O /tmp/terraform.zip
RUN unzip /tmp/terraform.zip -d /usr/local/bin
RUN rm -Rf /tmp/terraform.zip

RUN terraform version

RUN apk del git make go gcc libc-dev jq curl
