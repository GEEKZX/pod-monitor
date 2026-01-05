# Image URL to use all building/pushing image targets
IMG ?= podmonitor-controller:latest

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.PHONY: all
all: build

##@ General

.PHONY: help
help: ## 显示此帮助信息
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: manifests
manifests: controller-gen ## 生成 CRD 清单
	$(CONTROLLER_GEN) rbac:roleName=podmonitor-manager-role crd webhook paths="./..." output:crd:artifacts:config=config/crd/bases

.PHONY: generate
generate: controller-gen ## 生成代码
	$(CONTROLLER_GEN) object:headerFile="hack/boilerplate.go.txt" paths="./..."

.PHONY: fmt
fmt: ## 格式化代码
	go fmt ./...

.PHONY: vet
vet: ## 运行 go vet
	go vet ./...

.PHONY: test
test: manifests generate fmt vet ## 运行测试
	go test ./... -coverprofile cover.out

##@ Build

.PHONY: build
build: generate fmt vet ## 构建管理器二进制文件
	go build -o bin/manager main.go

.PHONY: run
run: manifests generate fmt vet ## 在本地运行控制器
	go run ./main.go

.PHONY: docker-build
docker-build: test ## 构建 docker 镜像
	docker build -t ${IMG} .

.PHONY: docker-push
docker-push: ## 推送 docker 镜像
	docker push ${IMG}

##@ Deployment

.PHONY: install
install: manifests ## 安装 CRD 到 K8s 集群
	kubectl apply -f config/crd/bases

.PHONY: uninstall
uninstall: manifests ## 从 K8s 集群卸载 CRD
	kubectl delete -f config/crd/bases

.PHONY: deploy
deploy: manifests ## 部署控制器到 K8s 集群
	cd config/manager && kustomize edit set image controller=${IMG}
	kubectl apply -k config/default

.PHONY: undeploy
undeploy: ## 从 K8s 集群卸载控制器
	kubectl delete -k config/default

##@ Build Dependencies

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Tool Binaries
CONTROLLER_GEN ?= $(LOCALBIN)/controller-gen

## Tool Versions
CONTROLLER_TOOLS_VERSION ?= v0.13.0

.PHONY: controller-gen
controller-gen: $(CONTROLLER_GEN) ## 下载 controller-gen 到本地
$(CONTROLLER_GEN): $(LOCALBIN)
	test -s $(LOCALBIN)/controller-gen || GOBIN=$(LOCALBIN) go install sigs.k8s.io/controller-tools/cmd/controller-gen@$(CONTROLLER_TOOLS_VERSION)

