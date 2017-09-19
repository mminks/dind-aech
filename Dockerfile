FROM docker:stable-dind

RUN mkdir -p /root/.docker
COPY config.json /root/.docker/config.json

RUN apk add --update git make go gcc libc-dev
RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login
RUN mv /root/go/bin/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login
RUN rm -Rf /root/go

RUN apk del git make go gcc libc-dev
