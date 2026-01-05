package utils

import (
	"fmt"
	"net/smtp"
	"os"
	"strings"
	"time"

	podmonitorv1 "github.com/pod-monitor/operator/api/v1"
)

// EmailSender 邮件发送器
type EmailSender struct {
	config *podmonitorv1.EmailNotificationConfig
}

// NewEmailSender 创建新的邮件发送器
func NewEmailSender(config *podmonitorv1.EmailNotificationConfig) *EmailSender {
	return &EmailSender{
		config: config,
	}
}

// SendZombiePodNotification 发送僵尸 Pod 通知邮件
func (e *EmailSender) SendZombiePodNotification(zombiePods []podmonitorv1.ZombiePodInfo) error {
	if !e.config.Enabled || len(zombiePods) == 0 {
		return nil
	}

	// 构建邮件内容
	subject := e.buildSubject(len(zombiePods))
	body := e.buildBody(zombiePods)

	// 发送邮件
	return e.sendEmail(subject, body)
}

// buildSubject 构建邮件主题
func (e *EmailSender) buildSubject(count int) string {
	subject := e.config.Subject
	if subject == "" {
		subject = "PodMonitor 僵尸 Pod 告警"
	}

	// 替换占位符
	subject = strings.ReplaceAll(subject, "{count}", fmt.Sprintf("%d", count))
	return fmt.Sprintf("%s - 发现 %d 个僵尸 Pod", subject, count)
}

// buildBody 构建邮件正文
func (e *EmailSender) buildBody(zombiePods []podmonitorv1.ZombiePodInfo) string {
	var builder strings.Builder

	builder.WriteString("PodMonitor 检测到以下僵尸 Pod：\n\n")
	builder.WriteString(strings.Repeat("=", 80))
	builder.WriteString("\n\n")

	for i, pod := range zombiePods {
		builder.WriteString(fmt.Sprintf("Pod #%d:\n", i+1))
		builder.WriteString(fmt.Sprintf("  名称: %s\n", pod.Name))
		builder.WriteString(fmt.Sprintf("  命名空间: %s\n", pod.Namespace))
		builder.WriteString(fmt.Sprintf("  状态: %s\n", pod.Status))
		builder.WriteString(fmt.Sprintf("  运行时长: %s\n", formatDuration(pod.RunDurationSeconds)))
		builder.WriteString(fmt.Sprintf("  创建时间: %s\n", pod.CreationTime.Format("2006-01-02 15:04:05")))
		builder.WriteString("\n")
	}

	builder.WriteString(strings.Repeat("=", 80))
	builder.WriteString("\n\n")
	builder.WriteString(fmt.Sprintf("总计: %d 个僵尸 Pod\n", len(zombiePods)))
	builder.WriteString(fmt.Sprintf("报告时间: %s\n", time.Now().Format("2006-01-02 15:04:05")))
	builder.WriteString("\n")
	builder.WriteString("请及时处理这些 Pod，避免资源浪费。\n")

	return builder.String()
}

// sendEmail 发送邮件
func (e *EmailSender) sendEmail(subject, body string) error {
	// 确定 SMTP 端口
	port := e.config.SMTPPort
	if port == 0 {
		if e.config.UseTLS {
			port = 587 // TLS 默认端口
		} else {
			port = 25 // 非加密默认端口
		}
	}

	// 确定用户名
	username := e.config.Username
	if username == "" {
		username = e.config.From
	}

	// 确定密码：优先使用配置中的密码，如果为空则从环境变量读取
	password := e.config.Password
	if password == "" {
		// 尝试从环境变量读取
		password = os.Getenv("SMTP_PASSWORD")
		if password == "" {
			return fmt.Errorf("SMTP 密码未配置，请在配置中设置 password 或设置环境变量 SMTP_PASSWORD")
		}
	}

	// 构建邮件消息
	msg := []byte(fmt.Sprintf("From: %s\r\n", e.config.From) +
		fmt.Sprintf("To: %s\r\n", strings.Join(e.config.Recipients, ",")) +
		fmt.Sprintf("Subject: %s\r\n", subject) +
		"Content-Type: text/plain; charset=UTF-8\r\n" +
		"\r\n" +
		body)

	// SMTP 地址
	addr := fmt.Sprintf("%s:%d", e.config.SMTPServer, port)

	// 认证
	auth := smtp.PlainAuth("", username, password, e.config.SMTPServer)

	// 发送邮件
	if e.config.UseTLS {
		// 使用 TLS
		return smtp.SendMail(addr, auth, e.config.From, e.config.Recipients, msg)
	} else {
		// 不使用 TLS（不推荐，但某些内部 SMTP 服务器可能需要）
		return smtp.SendMail(addr, auth, e.config.From, e.config.Recipients, msg)
	}
}

// formatDuration 格式化时长
func formatDuration(seconds int64) string {
	duration := time.Duration(seconds) * time.Second
	hours := int(duration.Hours())
	minutes := int(duration.Minutes()) % 60
	secs := int(duration.Seconds()) % 60

	if hours > 0 {
		return fmt.Sprintf("%d小时%d分钟%d秒", hours, minutes, secs)
	} else if minutes > 0 {
		return fmt.Sprintf("%d分钟%d秒", minutes, secs)
	}
	return fmt.Sprintf("%d秒", secs)
}

