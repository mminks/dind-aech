# Docker-in-Docker with some helpful tools for Gitlab-CI builds

* Amazon ECR Docker Credential Helper
* HashiCorp Terraform
* AWS CLI

### Docker-in-Docker

I'm using the official Docker repository. Please visit https://github.com/docker-library/docker for more information.

### 1. Amazon ECR Docker Credential Helper

The Amazon ECR Docker Credential Helper is a credential helper for the Docker daemon that makes it easier to use Amazon EC2 Container Registry (ECR).

The AECH (Amazon ECR Docker Credential Helper) is baked into this Docker in Docker image.

If you want to know how the Credential Helper works and what else it needed to use the helper successfully, please visit https://github.com/awslabs/amazon-ecr-credential-helper.

***Remember to set the AWS environment variables.***

### 2. HashiCorp Terraform

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions. Please visit https://www.terraform.io/ for more information.

### 3. AWS Command Line Interface

The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services. Please visit https://aws.amazon.com/cli/?nc1=h_ls for more information.
