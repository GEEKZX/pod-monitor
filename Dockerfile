# 构建阶段
FROM golang:1.20 as builder

WORKDIR /workspace

# 复制 go mod 文件（go.sum 如果存在也会被复制）
COPY go.mod go.sum* ./

# 复制源代码
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY utils/ utils/

# 生成 go.sum 文件并下载所有依赖
RUN go mod tidy

# 验证并下载所有依赖（确保 go.sum 完整）
RUN go mod verify && go mod download -x

# 安装 controller-gen 用于代码生成
# 在 alpine 镜像中，GOPATH 默认是 /go
ENV PATH=$PATH:/go/bin
# 使用更新的版本以确保正确生成嵌套结构体的 DeepCopy 方法
RUN go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.14.0

# 生成 DeepCopyObject 等代码（kubebuilder 标记需要）
# 使用 object 生成器为所有类型生成 DeepCopy 方法
# 使用 ./... 确保所有嵌套结构体都被处理
RUN controller-gen object paths="./..."

# 构建（-mod=mod 允许自动下载缺失的依赖）
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -mod=mod -a -o manager main.go

# 运行阶段
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]

