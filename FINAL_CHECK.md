# 全局重命名完成检查清单

## ✅ 已完成的重命名

### 核心代码文件
- ✅ `go.mod` - 模块路径: `github.com/pod-monitor/operator`
- ✅ `main.go` - 所有引用已更新
- ✅ `api/v1/podmonitor_types.go` - 类型名: `PodMonitor`, `PodMonitorSpec`, `PodMonitorStatus`, `ZombiePodInfo`
- ✅ `api/v1/groupversion_info.go` - Group: `podmonitor.pod-monitor.io`
- ✅ `controllers/podmonitor_controller.go` - 控制器: `PodMonitorReconciler`
- ✅ `utils/email.go` - 函数名和引用已更新

### Kubernetes 配置文件
- ✅ `config/crd/bases/podmonitor.pod-monitor.io_podmonitors.yaml` - CRD 名称和 group
- ✅ `config/rbac/*.yaml` - 所有 RBAC 资源
- ✅ `config/manager/*.yaml` - 部署配置
- ✅ `config/samples/*.yaml` - 示例配置

### Helm Chart
- ✅ `helm/podmonitor-operator/Chart.yaml` - Chart 名称: `podmonitor-operator`
- ✅ `helm/podmonitor-operator/values.yaml` - 所有配置项
- ✅ `helm/podmonitor-operator/templates/*.yaml` - 所有模板文件
- ✅ `helm/podmonitor-operator/crds/*.yaml` - CRD 定义
- ✅ `helm/podmonitor-operator/templates/_helpers.tpl` - Helper 函数

### 文档文件
- ✅ `README.md` - 主要文档
- ✅ `DEPLOY_ALIYUN.md` - 阿里云部署指南
- ✅ `HELM_DEPLOY.md` - Helm 部署指南
- ✅ `PUBLISH_HELM.md` - Helm 发布指南
- ✅ `QUICKSTART.md` - 快速开始指南
- ✅ `helm/podmonitor-operator/README.md` - Chart README

### 脚本文件
- ✅ `scripts/deploy-aliyun.sh` - 部署脚本
- ✅ `scripts/publish-helm.sh` - 发布脚本
- ✅ `scripts/publish-helm.bat` - Windows 发布脚本
- ✅ `scripts/quick-deploy.sh` - 快速部署脚本
- ✅ `Makefile` - 构建脚本

## 📋 命名规范

所有资源已统一使用以下命名：
- 项目名称: `pod-monitor`
- CRD Group: `podmonitor.pod-monitor.io`
- Kind: `PodMonitor`
- Plural: `podmonitors`
- Short Name: `pm`
- 命名空间: `podmonitor-system`
- 镜像名称: `podmonitor-controller`
- Chart 名称: `podmonitor-operator`

## ✅ 最新修复

1. **Makefile**: RBAC role 名称已更新为 `podmonitor-manager-role`
2. **Dockerfile**: 已添加 `utils/` 目录的复制

## 🚀 下一步

1. **运行依赖更新**:
   ```bash
   go mod tidy
   ```

2. **测试构建**:
   ```bash
   go build -o bin/manager main.go
   ```

3. **验证 Helm Chart**:
   ```bash
   helm lint ./helm/podmonitor-operator
   helm template test ./helm/podmonitor-operator
   ```

4. **验证部署**:
   ```bash
   # 检查 CRD 是否已安装
   kubectl get crd podmonitors.podmonitor.pod-monitor.io
   
   # 检查 Operator 是否运行
   kubectl get pods -n podmonitor-system
   ```

## ✅ 验证清单

- [ ] 所有代码编译通过
- [ ] Helm Chart 可以正常渲染
- [ ] CRD 可以正常安装
- [ ] 所有文档中的引用已更新
- [ ] 所有脚本中的引用已更新

