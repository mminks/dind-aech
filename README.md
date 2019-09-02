# Docker-in-Docker with some helpful tools for GitLab CI/CD builds

* Amazon ECR Docker Credential Helper
* HashiCorp Terraform
* AWS CLI (Command Line Interface)
* kubectl - The Kubernetes command-line tool

### Docker-in-Docker

I'm using the official Docker repository. Please visit https://github.com/docker-library/docker for more information.

### 1. Amazon ECR Docker Credential Helper

The Amazon ECR Docker Credential Helper is a credential helper for the Docker daemon that makes it easier to use Amazon EC2 Container Registry (ECR).

The AECH (Amazon ECR Docker Credential Helper) is baked into this Docker in Docker image.

If you want to know how the Credential Helper works and what else it needed to use the helper successfully, please visit https://github.com/awslabs/amazon-ecr-credential-helper.

***Remember to set the AWS environment variables.***

### 2. HashiCorp Terraform

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions. Please visit https://www.terraform.io/ for more information.

We will always build the latest version of Terraform. The latest 0.11.x binary is available under `/usr/local/bin/terraform0.11`. 

### 3. AWS Command Line Interface

The AWS Command Line Interface (CLI) is a unified tool to manage your AWS services. Please visit https://aws.amazon.com/cli/?nc1=h_ls for more information.

### 4. kubectl - The Kubernetes command-line tool

The Kubernetes command-line tool, kubectl, allows you to run commands against Kubernetes clusters. You can use kubectl to deploy applications, inspect and manage cluster resources, and view logs.

### 5. Usage in GitLab CI/CD Pipelines

Add something like the following to your `.gitlab-ci.yml`:

#### 5.1 Deploy to Docker Compose

```
TODO
```

#### 5.2 Deploy to Docker Swarm

```
  before_script:
    - eval $(ssh-agent) && setup_ssh.sh s3-bucket/path/to/your/private_ssh_key
  script:
    - deploy_to_swarm.sh "app-name" "ec2-user@swarm.example.com" [ssm/path/to/your/credentials]
```

#### 5.3 Deploy to Kubernetes (K8s)

```
  before_script:
    - aws s3 cp s3://path-to-your-k8s/config ~/.kube
  script:
    - deploy_to_kubernetes.sh k8s
```

The "k8s" in `deploy_to_kubernetes.sh k8s` is either a file or directory to your K8s manifests.