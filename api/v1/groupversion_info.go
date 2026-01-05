// Package v1 包含 PodMonitor API 的类型定义
package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

var (
	// GroupVersion 是此 API 组的版本
	GroupVersion = schema.GroupVersion{Group: "podmonitor.pod-monitor.io", Version: "v1"}

	// SchemeBuilder 用于将此 API 组添加到 Scheme
	SchemeBuilder = runtime.NewSchemeBuilder(addKnownTypes)

	// AddToScheme 将类型添加到 Scheme
	AddToScheme = SchemeBuilder.AddToScheme
)

// Resource 返回 GroupResource
func Resource(resource string) schema.GroupResource {
	return GroupVersion.WithResource(resource).GroupResource()
}

// addKnownTypes 添加已知类型到 Scheme
func addKnownTypes(scheme *runtime.Scheme) error {
	scheme.AddKnownTypes(GroupVersion,
		&PodMonitor{},
		&PodMonitorList{},
	)
	metav1.AddToGroupVersion(scheme, GroupVersion)
	return nil
}

