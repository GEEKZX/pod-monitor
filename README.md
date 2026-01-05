# PodMonitor Operator

一个云原生的 Kubernetes Operator，用于监控集群中的 Pod 运行时长，自动检测和清理僵尸 Pod，避免在弹性节点上浪费资源。

## 功能特性

- 🔍 **自动监控**: 定期检查指定命名空间中的 Pod 运行状态
- 🧟 **僵尸 Pod 检测**: 自动识别超过最大运行时长的 Pod
- 🧹 **自动清理**: 可配置自动清理僵尸 Pod，释放资源
- 🏷️ **标签过滤**: 支持通过标签选择器过滤要监控的 Pod
- 📊 **状态报告**: 提供详细的监控状态和僵尸 Pod 列表
- 📧 **邮件通知**: 自动发送僵尸 Pod 告警邮件给运维团队

## 架构

该 Operator 基于 Kubernetes Controller Runtime 构建，使用自定义资源定义 (CRD) 来配置监控策略。

### 核心组件

1. **PodMonitor CRD**: 定义监控配置和状态
2. **PodMonitor Controller**: 实现监控和清理逻辑
3. **RBAC**: 提供必要的权限管理

## 快速开始

### 前置要求

- Kubernetes 1.20+
- kubectl 配置并连接到集群
- Go 1.21+ (用于本地开发)
- Docker (用于构建镜像)

### 安装方式

#### 方式一：使用 Helm（推荐）

```bash
# 1. 设置镜像地址
export IMAGE="registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller:v1.0.0"

# 2. 安装
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller \
  --set image.tag=v1.0.0
```

详细步骤请参考 [Helm 部署指南](HELM_DEPLOY.md)

#### 方式二：使用部署脚本

```bash
# 1. 设置环境变量（根据你的实际情况修改）
export ACR_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
export ACR_NAMESPACE="your-namespace"
export IMAGE_TAG="v1.0.0"

# 2. 给脚本添加执行权限
chmod +x scripts/deploy-aliyun.sh

# 3. 运行部署脚本
./scripts/deploy-aliyun.sh
```

详细步骤请参考 [阿里云部署指南](DEPLOY_ALIYUN.md)

### 本地开发安装

1. **安装 CRD**:
```bash
make install
```

2. **部署 Operator**:
```bash
make deploy
```

3. **创建监控实例**:
```bash
kubectl apply -f config/samples/podmonitor_v1_podmonitor.yaml
```

### 配置说明

PodMonitor 资源支持以下配置参数：

- `namespaces`: 要监控的命名空间列表（空则监控所有命名空间）
- `labelSelector`: 标签选择器，用于过滤 Pod
- `maxRunDurationSeconds`: 最大运行时长（秒），超过此时间视为僵尸 Pod
- `checkIntervalSeconds`: 检查间隔（秒）
- `autoCleanup`: 是否自动清理僵尸 Pod
- `gracePeriodSeconds`: 清理前的宽限期（秒）
- `emailNotification`: 邮件通知配置（可选）
  - `enabled`: 是否启用邮件通知
  - `recipients`: 收件人邮箱列表
  - `smtpServer`: SMTP 服务器地址
  - `smtpPort`: SMTP 端口（默认 587 for TLS, 25 for 非加密）
  - `from`: 发件人邮箱
  - `username`: SMTP 用户名（可选，默认使用 from）
  - `password`: SMTP 密码（可选，可通过环境变量 `SMTP_PASSWORD` 设置）
  - `useTLS`: 是否使用 TLS（默认 true）
  - `subject`: 邮件主题（可选，支持 `{count}` 占位符）

### 示例配置

```yaml
apiVersion: podmonitor.pod-monitor.io/v1
kind: PodMonitor
metadata:
  name: podmonitor-sample
spec:
  namespaces:
    - default
    - production
  labelSelector:
    app: batch-job
  maxRunDurationSeconds: 3600  # 1小时
  checkIntervalSeconds: 60     # 每分钟检查一次
  autoCleanup: true
  gracePeriodSeconds: 300       # 5分钟宽限期
  
  # 邮件通知配置
  emailNotification:
    enabled: true
    recipients:
      - ops-team@example.com
      - devops@example.com
    smtpServer: smtp.example.com
    smtpPort: 587
    from: podmonitor@example.com
    useTLS: true
    # 密码建议通过环境变量 SMTP_PASSWORD 设置
```

## 开发

### 本地运行

```bash
make run
```

### 构建

```bash
make build
```

### 测试

```bash
make test
```

### 构建 Docker 镜像

```bash
make docker-build
```

## 邮件通知

### 基本配置

邮件通知功能会在检测到僵尸 Pod 时自动发送告警邮件。配置示例：

```yaml
emailNotification:
  enabled: true
  recipients:
    - ops-team@example.com
  smtpServer: smtp.example.com
  smtpPort: 587
  from: podmonitor@example.com
  useTLS: true
```

### 安全配置（推荐）

为了安全，建议通过 Kubernetes Secret 存储 SMTP 密码：

1. **创建 Secret**:
```bash
kubectl create secret generic smtp-credentials \
  --from-literal=password='your-smtp-password' \
  -n podmonitor-system
```

2. **在 Deployment 中添加环境变量**（修改 `config/manager/manager.yaml`）:
```yaml
env:
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: smtp-credentials
      key: password
```

3. **在 PodMonitor 配置中不设置 password 字段**，系统会自动从环境变量读取。

### 邮件内容

邮件包含以下信息：
- 僵尸 Pod 列表（名称、命名空间、状态、运行时长、创建时间）
- Pod 总数统计
- 报告生成时间

## 监控状态

查看监控状态：

```bash
kubectl get podmonitor podmonitor-sample -o yaml
```

状态信息包括：
- `totalPods`: 监控的 Pod 总数
- `zombiePods`: 僵尸 Pod 数量
- `cleanedPods`: 已清理的 Pod 数量
- `lastCheckTime`: 最后检查时间
- `zombiePodList`: 僵尸 Pod 详细信息列表

## 清理

卸载 Operator：

```bash
make undeploy
make uninstall
```

## 许可证

MIT License

