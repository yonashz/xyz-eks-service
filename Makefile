SHELL := /bin/bash
IMAGE_NAME=xyz-app
TAG=0.1.0
ACCOUNT_ID=568903012602
# Ensure S3, ECR are created
.PHONY: setup
setup:
	@if aws s3 ls "s3://xyz-tfstate" 2>&1 | grep -q 'NoSuchBucket'; then \
		echo "State bucket doesn't exist, creating..."; \
		aws s3 mb s3://xyz-tfstate; \
	else \
		echo "Bucket already exists."; \
	fi

	aws ecr describe-repositories --repository-names xyz-images || aws ecr create-repository --repository-name xyz-images
	aws ecr describe-repositories --repository-names xyz-helm  || aws ecr create-repository --repository-name xyz-helm

.PHONY: build
build:
	docker build -t $(IMAGE_NAME) .

.PHONY: push
push:
	aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 568903012602.dkr.ecr.us-east-2.amazonaws.com
	docker tag xyz-app:latest 568903012602.dkr.ecr.us-east-2.amazonaws.com/xyz-images:$(TAG)
	docker push 568903012602.dkr.ecr.us-east-2.amazonaws.com/xyz-images:$(TAG)

.PHONY: init
init:
	terraform init

.PHONY: validate
validate:
	terraform fmt -recursive
	terraform validate

.PHONY: plan
plan:
	terraform validate
	terraform plan 

.PHONY: apply
apply:
    terraform apply --auto-approve

.PHONY: destroy
destroy:
    terraform destroy 

.PHONY: all
all: setup build push init validate plan apply destroy