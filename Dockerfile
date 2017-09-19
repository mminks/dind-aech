FROM docker:stable-dind

RUN mkdir -p /root/.docker
COPY config.json /root/.docker/config.json

RUN apk add --update git make go gcc libc-dev
RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login
RUN mv /root/go/bin/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login
RUN rm -Rf /root/go

RUN wget $(curl -Ls https://releases.hashicorp.com/index.json | jq '{terraform}' | egrep linux_amd64 | sort -r| head -1| awk '{print $2}' | sed 's/"//g') -O /tmp/terraform.zip
RUN unzip /tmp/terraform.zip -d /usr/local/bin
RUN rm -Rf /tmp/terraform.zip

RUN apk del git make go gcc libc-dev
