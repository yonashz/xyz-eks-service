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

	aws ecr describe-repositories --repository-names xyz/xyz-app || aws ecr create-repository --repository-name xyz-app

.PHONY: build
build:
	docker build -t $(IMAGE_NAME) .

.PHONY: push
push:
	aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 568903012602.dkr.ecr.us-east-2.amazonaws.com
	docker tag xyz-app:latest 568903012602.dkr.ecr.us-east-2.amazonaws.com/xyz-app:$(TAG)
	docker push 568903012602.dkr.ecr.us-east-2.amazonaws.com/xyz-app:$(TAG)

# init:
# 	terraform init

# validate:
# 	terraform fmt -recursive
# 	terraform validate

# plan:
# 	terraform validate
# 	terraform plan -var-file="variables.tfvars"

# apply:
#     terraform apply -var-file="variables.tfvars" --auto-approve

# destroy:
#     terraform destroy -var-file="variables.tfvars"

# all: build tag push init validate plan apply destroy