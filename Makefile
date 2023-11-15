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

.PHONY: updateKubeConfig
updateKubeConfig:
	aws eks update-kubeconfig --region us-east-2 --name xyz-cluster

.PHONY: argoInit
argoInit:
	kubectl config set-context --current --namespace=argocd
	argocd login --core
	argocd app create apps \
	--dest-namespace argocd \
	--dest-server https://kubernetes.default.svc \
	--repo https://github.com/yonashz/xyz-eks-service.git \
	--path argocd-apps
	argocd app wait apps --operation && argocd app sync apps
	sleep 5
	argocd app wait aws-load-balancer-controller --operation && argocd app sync aws-load-balancer-controller
	sleep 5
	argocd app wait external-dns --operation && argocd app sync external-dns
	sleep 5
	argocd app wait external-dns --operation && argocd app sync external-dns
	sleep 5
	argocd app wait xyz-app --operation && argocd app sync xyz-app
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

.PHONY: testCluster
testCluster: 
	aws eks update-kubeconfig --region us-east-2 --name xyz-cluster
	cd tests && go mod tidy && go clean -testcache && go test -v -cover .

.PHONY: destroy
destroy:
	aws eks update-kubeconfig --region us-east-2 --name xyz-cluster
	kubectl config set-context --current --namespace=argocd
	argocd login --core
	argocd app delete xyz-app
	sleep 30 # Give the LB controller time to delete resources
	argocd app delete apps --cascade
	@if aws s3 ls "s3://xyz-tfstate" 2>&1 | grep -q 'NoSuchBucket'; then \
		echo "State bucket doesn't exist, nothing to do."; \
	else \
		cd terraform && terraform init && terraform destroy --auto-approve; \
	fi
	aws ecr delete-repository --repository-name xyz-images --force

.PHONY: all
all: setup build test push init validate plan apply updateKubeConfig argoInit

.PHONY: allTF
allTF: setup init validate plan apply updateKubeConfig argoInit