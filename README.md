# xyz-eks-service
Code and documentation to create an EKS cluster, bootstrap it, and deploy/expose a simple Go REST API.  A Makefile exists as the entrypoint into each individual component of the process, along with an `all` target to run everything at once.

---

## Overview
The Go app listens on port 8080 and returns a JSON payload consisting of a static message and a Unix format timestamp:
```
{"Message":"It Follows is a cinema masterpiece.","Timestamp":1699532803}
```

The app is unit tested, containerized and packaged into a Helm chart.  Both the container image and the Helm chart are pushed to Amazon ECR.  The underlying platform running the application is Amazon EKS.  EKS is fully configured and deployed through Terraform.  Once the EKS cluster is stood up and both the app and core Kubernetes components are fully deployed, a final test is run to ensure everything is healthy.

---

## Usage

## Prerequisites

The xyz-eks-service repository holds all the necessary code to deploy the solution from a local machine, however, there are a few prerequisites: 

- [Terraform](https://developer.hashicorp.com/terraform/install) installed (version 1.5.7 or higher)
- AWS credentials set as environment variables
  - The policy/policies attached must be permissive enough to complete all necessary deployment steps, including VPC, EKS, IAM role (used for IAM Roles for Service Accounts or IRSA) creation and configuration.  
  - They must also be able to create the ECR repositories used for the image and Helm chart, and the S3 bucket for Terraform state
  - Production recommendation would be to use a secrets manager like Hashicorp Vault or AWS Secrets Manager.  IAM Identity Center offers secure ways to generate temporary credentials as well.
- Docker installed (I used version 24.0.6, build ed223bc, and I used [Docker Desktop](https://www.docker.com/products/docker-desktop/) to manage my install)
  - Docker Desktop is free for non-enterprises.  Use [Rancher Desktop](https://docs.rancherdesktop.io/getting-started/installation/) if there are any licensing issues
- A domain and hosted zone in Route 53 if hitting the service from the Ingress (ALB). 

Optional: If you want to run the Go service locally, or run the test, you'll need to install [Go](https://go.dev/doc/install)

---

## Deployment

Deployment is completely handled by the Makefile bundled with the repository. The available targets are:

```
setup: Ensures S3 bucket and ECR repositories are created.
build: Runs the Docker build against the Go service.
test: Runs a small unit test against the Go service.
push: Tags and pushes the Docker image to ECR.
helm: Packages and pushes the app in a Helm chart.
init: Runs a Terraform init.
validate: Runs a Terraform validate.
plan: Runs a Terraform plan.
apply: Runs a Terraform apply.
destroy: Runs a Terraform destroy.  Also deletes the S3 bucket and ECR repositories.
all: Runs all steps in sequential order, except destroy.
```

---

## EKS Components

EKS is deployed using the standard public EKS Terraform module.  A VPC and underlying networking services used by EKS are also deployed using the standard public module for VPC.  IRSA (IAM Roles for Service Accounts) are deployed with a public module in order for VPC CNI and the AWS load balancer controller to have the appropriate amount of IAM permissions needed.

EKS is using a managed node group for its worker nodes.  Capacity is set to 1 to save on costs, running a t3.small (the smallest recommended EC2 instance for EKS).

Finally, the Go application itself is deployed to EKS using Terraform + a Helm chart.

---

## Cleanup

Cleanup is done using `make destroy`.  This will tear down all Terraform managed components, and delete the S3 bucket and ECR repositories.