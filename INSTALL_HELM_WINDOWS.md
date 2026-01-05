# Windows 安装 Helm 指南

Helm 完全支持 Windows 系统。以下是几种安装方法：

## 方法 1: 使用 Chocolatey（推荐）

如果你已经安装了 Chocolatey 包管理器：

```powershell
# 以管理员身份运行 PowerShell
choco install kubernetes-helm
```

安装完成后验证：
```powershell
helm version
```

## 方法 2: 使用 winget（Windows 10/11 内置）

Windows 10/11 自带 winget 包管理器：

```powershell
winget install Helm.Helm
```

安装完成后验证：
```powershell
helm version
```

## 方法 3: 使用 Scoop

如果你使用 Scoop 包管理器：

```powershell
scoop install helm
```

## 方法 4: 手动安装

### 步骤 1: 下载 Helm

1. 访问 [Helm GitHub Releases](https://github.com/helm/helm/releases)
2. 下载最新版本的 Windows 安装包（例如：`helm-v3.13.0-windows-amd64.zip`）

### 步骤 2: 解压文件

1. 解压下载的 `.zip` 文件
2. 你会得到一个 `windows-amd64` 文件夹，里面包含 `helm.exe`

### 步骤 3: 添加到 PATH

**方式 A: 通过系统设置**
1. 将 `helm.exe` 复制到一个固定位置（例如：`C:\Program Files\Helm\`）
2. 右键"此电脑" -> "属性" -> "高级系统设置" -> "环境变量"
3. 在"系统变量"中找到 `Path`，点击"编辑"
4. 点击"新建"，添加 Helm 所在目录（例如：`C:\Program Files\Helm\`）
5. 点击"确定"保存

**方式 B: 通过 PowerShell（管理员）**
```powershell
# 假设 helm.exe 在 C:\Program Files\Helm\
$helmPath = "C:\Program Files\Helm"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$helmPath", [EnvironmentVariableTarget]::Machine)
```

### 步骤 4: 验证安装

打开新的 PowerShell 或命令提示符窗口：

```powershell
helm version
```

如果看到版本信息，说明安装成功！

## 验证安装

安装完成后，运行以下命令验证：

```powershell
# 检查 Helm 版本
helm version

# 检查 Helm 是否正常工作
helm help
```

## 常见问题

### Q: 提示 "helm: command not found"
**A**: 说明 PATH 环境变量没有正确配置，或者需要重启终端窗口。

### Q: 如何更新 Helm？
**A**: 
- Chocolatey: `choco upgrade kubernetes-helm`
- winget: `winget upgrade Helm.Helm`
- 手动: 下载新版本，替换旧文件

### Q: 需要管理员权限吗？
**A**: 
- Chocolatey/winget: 需要管理员权限
- 手动安装到用户目录: 不需要管理员权限

## 下一步

安装完成后，你可以：
1. 使用 Helm 管理 Kubernetes 应用
2. 发布你的 Helm Chart（参考 `PUBLISH_HELM.md`）
3. 从 Helm Repository 安装应用

## 参考链接

- [Helm 官方文档](https://helm.sh/docs/)
- [Helm GitHub Releases](https://github.com/helm/helm/releases)
- [Chocolatey 官网](https://chocolatey.org/)
- [Scoop 官网](https://scoop.sh/)

