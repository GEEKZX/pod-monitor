package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// PodMonitorSpec 定义了 PodMonitor 的期望状态
type PodMonitorSpec struct {
	// 监控的命名空间列表，如果为空则监控所有命名空间
	Namespaces []string `json:"namespaces,omitempty"`

	// 标签选择器，用于过滤要监控的 Pod
	LabelSelector map[string]string `json:"labelSelector,omitempty"`

	// 最大运行时长（秒），超过此时间的 Pod 将被视为僵尸 Pod
	MaxRunDurationSeconds int64 `json:"maxRunDurationSeconds"`

	// 检查间隔（秒），每隔多长时间检查一次 Pod 状态
	CheckIntervalSeconds int64 `json:"checkIntervalSeconds,omitempty"`

	// 是否自动清理僵尸 Pod
	AutoCleanup bool `json:"autoCleanup,omitempty"`

	// 清理前的宽限期（秒），给 Pod 一些时间完成
	GracePeriodSeconds int64 `json:"gracePeriodSeconds,omitempty"`

	// 邮件通知配置
	EmailNotification *EmailNotificationConfig `json:"emailNotification,omitempty"`
}

// EmailNotificationConfig 邮件通知配置
type EmailNotificationConfig struct {
	// 是否启用邮件通知
	Enabled bool `json:"enabled,omitempty"`

	// 收件人邮箱列表
	Recipients []string `json:"recipients"`

	// SMTP 服务器地址
	SMTPServer string `json:"smtpServer"`

	// SMTP 端口
	SMTPPort int `json:"smtpPort,omitempty"`

	// 发件人邮箱
	From string `json:"from"`

	// SMTP 用户名（可选，如果为空则使用 From）
	Username string `json:"username,omitempty"`

	// SMTP 密码（建议使用 Secret 引用）
	Password string `json:"password,omitempty"`

	// 是否使用 TLS
	UseTLS bool `json:"useTLS,omitempty"`

	// 邮件主题模板（可选，支持 {count} 占位符）
	Subject string `json:"subject,omitempty"`
}

// PodMonitorStatus 定义了 PodMonitor 的观察状态
type PodMonitorStatus struct {
	// 监控的 Pod 总数
	TotalPods int `json:"totalPods,omitempty"`

	// 僵尸 Pod 数量
	ZombiePods int `json:"zombiePods,omitempty"`

	// 已清理的 Pod 数量
	CleanedPods int `json:"cleanedPods,omitempty"`

	// 最后检查时间
	LastCheckTime metav1.Time `json:"lastCheckTime,omitempty"`

	// 僵尸 Pod 列表
	ZombiePodList []ZombiePodInfo `json:"zombiePodList,omitempty"`
}

// ZombiePodInfo 僵尸 Pod 信息
type ZombiePodInfo struct {
	// Pod 名称
	Name string `json:"name"`

	// 命名空间
	Namespace string `json:"namespace"`

	// 运行时长（秒）
	RunDurationSeconds int64 `json:"runDurationSeconds"`

	// 创建时间
	CreationTime metav1.Time `json:"creationTime"`

	// 状态
	Status string `json:"status"`
}

//+kubebuilder:object:root=true
//+kubebuilder:subresource:status

// PodMonitor 是用于监控 Kubernetes Pod 的 CRD
type PodMonitor struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   PodMonitorSpec   `json:"spec,omitempty"`
	Status PodMonitorStatus `json:"status,omitempty"`
}

//+kubebuilder:object:root=true

// PodMonitorList 包含多个 PodMonitor 对象
type PodMonitorList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []PodMonitor `json:"items"`
}

func init() {
	SchemeBuilder.Register(&PodMonitor{}, &PodMonitorList{})
}

