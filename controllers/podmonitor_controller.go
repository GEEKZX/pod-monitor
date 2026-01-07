package controllers

import (
	"context"
	"fmt"
	"time"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/log"

	podmonitorv1 "github.com/pod-monitor/operator/api/v1"
	"github.com/pod-monitor/operator/utils"
)

// PodMonitorReconciler 协调 PodMonitor 资源
type PodMonitorReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=podmonitor.pod-monitor.io,resources=podmonitors,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=podmonitor.pod-monitor.io,resources=podmonitors/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=podmonitor.pod-monitor.io,resources=podmonitors/finalizers,verbs=update
//+kubebuilder:rbac:groups="",resources=pods,verbs=get;list;watch;delete

// Reconcile 是主要的协调循环
func (r *PodMonitorReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx)

	// 获取 PodMonitor 实例
	var podMonitor podmonitorv1.PodMonitor
	if err := r.Get(ctx, req.NamespacedName, &podMonitor); err != nil {
		logger.Error(err, "无法获取 PodMonitor")
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	// 检查是否需要执行监控检查
	checkInterval := time.Duration(podMonitor.Spec.CheckIntervalSeconds) * time.Second
	if podMonitor.Spec.CheckIntervalSeconds == 0 {
		checkInterval = 60 * time.Second // 默认 60 秒
	}

	// 如果距离上次检查时间不足，则跳过
	if !podMonitor.Status.LastCheckTime.IsZero() {
		timeSinceLastCheck := time.Since(podMonitor.Status.LastCheckTime.Time)
		if timeSinceLastCheck < checkInterval {
			nextCheck := checkInterval - timeSinceLastCheck
			logger.Info("距离上次检查时间过短，等待下次检查", "等待时间", nextCheck)
			return ctrl.Result{RequeueAfter: nextCheck}, nil
		}
	}

	logger.Info("开始监控 Pod")

	// 执行监控检查
	if err := r.performMonitoring(ctx, &podMonitor); err != nil {
		logger.Error(err, "监控检查失败")
		return ctrl.Result{RequeueAfter: checkInterval}, err
	}

	// 更新状态
	if err := r.Status().Update(ctx, &podMonitor); err != nil {
		logger.Error(err, "更新状态失败")
		return ctrl.Result{RequeueAfter: checkInterval}, err
	}

	logger.Info("监控检查完成", 
		"总 Pod 数", podMonitor.Status.TotalPods,
		"僵尸 Pod 数", podMonitor.Status.ZombiePods)

	// 设置下次检查时间
	return ctrl.Result{RequeueAfter: checkInterval}, nil
}

// performMonitoring 执行实际的监控逻辑
func (r *PodMonitorReconciler) performMonitoring(ctx context.Context, podMonitor *podmonitorv1.PodMonitor) error {
	logger := log.FromContext(ctx)

	// 获取要监控的命名空间列表
	namespaces := podMonitor.Spec.Namespaces
	if len(namespaces) == 0 {
		// 如果未指定命名空间，获取所有命名空间
		var nsList corev1.NamespaceList
		if err := r.List(ctx, &nsList); err != nil {
			return fmt.Errorf("获取命名空间列表失败: %w", err)
		}
		for _, ns := range nsList.Items {
			namespaces = append(namespaces, ns.Name)
		}
	}

	var allPods []corev1.Pod
	var zombiePods []podmonitorv1.ZombiePodInfo

	maxDuration := time.Duration(podMonitor.Spec.MaxRunDurationSeconds) * time.Second
	now := time.Now()

	// 遍历所有命名空间查找 Pod
	for _, ns := range namespaces {
		var podList corev1.PodList
		
		// 构建标签选择器
		listOptions := []client.ListOption{
			client.InNamespace(ns),
		}
		
		if len(podMonitor.Spec.LabelSelector) > 0 {
			selector := labels.SelectorFromSet(podMonitor.Spec.LabelSelector)
			listOptions = append(listOptions, client.MatchingLabelsSelector{Selector: selector})
		}

		if err := r.List(ctx, &podList, listOptions...); err != nil {
			logger.Error(err, "获取 Pod 列表失败", "命名空间", ns)
			continue
		}

		for _, pod := range podList.Items {
			// 跳过已完成的 Pod（Succeeded 或 Failed）
			if pod.Status.Phase == corev1.PodSucceeded || pod.Status.Phase == corev1.PodFailed {
				continue
			}

			allPods = append(allPods, pod)

			// 检查 Pod 是否为僵尸 Pod
			if isZombie := r.isZombiePod(ctx, &pod, maxDuration, now); isZombie {
				runDuration := now.Sub(pod.CreationTimestamp.Time)
				zombieInfo := podmonitorv1.ZombiePodInfo{
					Name:               pod.Name,
					Namespace:          pod.Namespace,
					RunDurationSeconds: int64(runDuration.Seconds()),
					CreationTime:       pod.CreationTimestamp,
					Status:             getPodStatus(&pod),
				}
				zombiePods = append(zombiePods, zombieInfo)

				// 如果启用了自动清理，则清理僵尸 Pod
				if podMonitor.Spec.AutoCleanup {
					if err := r.cleanupZombiePod(ctx, &pod, podMonitor.Spec.GracePeriodSeconds); err != nil {
						logger.Error(err, "清理僵尸 Pod 失败", "Pod", pod.Name, "命名空间", pod.Namespace)
					} else {
						logger.Info("已清理僵尸 Pod", "Pod", pod.Name, "命名空间", pod.Namespace)
						podMonitor.Status.CleanedPods++
					}
				}
			}
		}
	}

	// 更新状态
	podMonitor.Status.TotalPods = len(allPods)
	podMonitor.Status.ZombiePods = len(zombiePods)
	podMonitor.Status.ZombiePodList = zombiePods
	podMonitor.Status.LastCheckTime = metav1.Now()

	// 如果检测到僵尸 Pod，打印列表
	if len(zombiePods) > 0 {
		// 打印标题
		logger.Info(fmt.Sprintf("========== 检测到 %d 个僵尸 Pod ==========", len(zombiePods)))
		
		for i, zombie := range zombiePods {
			// 将秒转换为天
			days := float64(zombie.RunDurationSeconds) / 86400.0
			var daysStr string
			if days < 1 {
				daysStr = fmt.Sprintf("%.2f 天", days) // 小于1天显示小数
			} else {
				daysStr = fmt.Sprintf("%.0f 天", days) // 大于等于1天显示整数
			}
			
			// 每个僵尸 Pod 单独一行日志，确保正确换行
			logger.Info(fmt.Sprintf("[%d] %s/%s | 运行时长: %s | 状态: %s | 创建时间: %s",
				i+1,
				zombie.Namespace,
				zombie.Name,
				daysStr,
				zombie.Status,
				zombie.CreationTime.Format("2006-01-02 15:04:05")))
		}
		logger.Info("===================================================")
	}

	// 如果检测到僵尸 Pod 且配置了邮件通知，发送邮件
	if len(zombiePods) > 0 && podMonitor.Spec.EmailNotification != nil {
		emailSender := utils.NewEmailSender(podMonitor.Spec.EmailNotification)
		if err := emailSender.SendZombiePodNotification(zombiePods); err != nil {
			logger.Error(err, "发送邮件通知失败", "僵尸 Pod 数", len(zombiePods))
			// 邮件发送失败不影响主流程，只记录错误
		} else {
			logger.Info("已发送僵尸 Pod 邮件通知", "收件人", podMonitor.Spec.EmailNotification.Recipients, "僵尸 Pod 数", len(zombiePods))
		}
	}

	return nil
}

// isZombiePod 判断 Pod 是否为僵尸 Pod
func (r *PodMonitorReconciler) isZombiePod(ctx context.Context, pod *corev1.Pod, maxDuration time.Duration, now time.Time) bool {
	// 如果 Pod 已完成或失败，不算僵尸 Pod
	if pod.Status.Phase == corev1.PodSucceeded || pod.Status.Phase == corev1.PodFailed {
		return false
	}

	// 计算 Pod 运行时长
	runDuration := now.Sub(pod.CreationTimestamp.Time)
	
	// 如果运行时间超过最大运行时长，视为僵尸 Pod
	if runDuration > maxDuration {
		// 检查 Pod 状态
		switch pod.Status.Phase {
		case corev1.PodRunning, corev1.PodPending:
			// Running 或 Pending 状态但运行时间过长，视为僵尸 Pod
			return true
		case corev1.PodUnknown:
			// Unknown 状态且运行时间过长，视为僵尸 Pod
			return true
		default:
			// 其他状态且运行时间过长，视为僵尸 Pod
			return true
		}
	}

	return false
}

// cleanupZombiePod 清理僵尸 Pod
func (r *PodMonitorReconciler) cleanupZombiePod(ctx context.Context, pod *corev1.Pod, gracePeriodSeconds int64) error {
	logger := log.FromContext(ctx)

	// 如果设置了宽限期，等待一段时间
	if gracePeriodSeconds > 0 {
		gracePeriod := time.Duration(gracePeriodSeconds) * time.Second
		runDuration := time.Since(pod.CreationTimestamp.Time)
		if runDuration < gracePeriod {
			remaining := gracePeriod - runDuration
			logger.Info("等待宽限期", "Pod", pod.Name, "剩余时间", remaining)
			time.Sleep(remaining)
		}
	}

	// 删除 Pod
	deleteOptions := client.DeleteOptions{
		GracePeriodSeconds: &[]int64{0}[0], // 立即删除
	}

	if err := r.Delete(ctx, pod, &deleteOptions); err != nil {
		return fmt.Errorf("删除 Pod 失败: %w", err)
	}

	return nil
}

// getPodStatus 获取 Pod 状态字符串
func getPodStatus(pod *corev1.Pod) string {
	switch pod.Status.Phase {
	case corev1.PodPending:
		return "Pending"
	case corev1.PodRunning:
		return "Running"
	case corev1.PodSucceeded:
		return "Succeeded"
	case corev1.PodFailed:
		return "Failed"
	case corev1.PodUnknown:
		return "Unknown"
	default:
		return string(pod.Status.Phase)
	}
}

// SetupWithManager 设置控制器管理器
func (r *PodMonitorReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&podmonitorv1.PodMonitor{}).
		Complete(r)
}

