# 构建阶段
FROM golang:1.21 as builder

WORKDIR /workspace

# 复制 go mod 文件
COPY go.mod go.mod
COPY go.sum go.sum

# 下载依赖
RUN go mod download

# 复制源代码
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY utils/ utils/

# 构建
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o manager main.go

# 运行阶段
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]

