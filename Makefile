SHELL := /bin/bash
IMAGE_NAME=xyz-app
CHARTVERSION=0.4.0
TAG=0.2.0
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

.PHONY: build
build:
	docker build --target development -t $(IMAGE_NAME):$(TAG) .

.PHONY: test
test:
	docker build --progress=plain --target test -t $(IMAGE_NAME) .

.PHONY: push
push:	
	aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 568903012602.dkr.ecr.us-east-2.amazonaws.com
	docker tag xyz-app:$(TAG) 568903012602.dkr.ecr.us-east-2.amazonaws.com/xyz-images:$(TAG)
	docker push 568903012602.dkr.ecr.us-east-2.amazonaws.com/xyz-images:$(TAG)

.PHONY: init
init:
	cd terraform && terraform init

.PHONY: validate
validate:
	cd terraform && terraform fmt -recursive
	cd terraform && terraform validate

.PHONY: plan
plan:
	cd terraform && terraform plan

.PHONY: apply
apply:
	cd terraform && terraform apply --auto-approve

.PHONY: testCluster
testCluster: 
	cd tests && go mod tidy && go clean -testcache && go test -v -cover .

.PHONY: destroy
destroy:
	@if aws s3 ls "s3://xyz-tfstate" 2>&1 | grep -q 'NoSuchBucket'; then \
		echo "State bucket doesn't exist, nothing to do."; \
	else \
		cd terraform && terraform destroy; \
		aws s3 rb s3://xyz-tfstate --force; \
	fi
	aws ecr delete-repository --repository-name xyz-images --force

.PHONY: all
all: setup build test push init validate plan apply testCluster