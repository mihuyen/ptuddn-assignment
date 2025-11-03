# 🚨 AlertManager Setup Guide

## Mô tả
Cảnh báo tự động khi:
- **CPU > 80%** trong 1 phút
- **Memory > 90%** trong 2 phút
- **Error Rate > 5%** trong 5 phút
- **Pod Restarts > 2** lần trong 15 phút

## Deployment

### 1. Build Webhook Receiver Image
```powershell
docker build -f Dockerfile.webhook -t webhook-receiver:latest .
```

### 2. Deploy AlertManager, Prometheus Rules, Webhook Receiver
```powershell
# Cập nhật Prometheus config
kubectl apply -f k8s/prometheus-configmap-new.yaml --force

# Cập nhật Prometheus deployment
kubectl apply -f k8s/prometheus-deployment-new.yaml --force

# Deploy alert rules
kubectl apply -f k8s/prometheus-rules.yaml

# Deploy AlertManager
kubectl apply -f k8s/alertmanager-config.yaml
kubectl apply -f k8s/alertmanager-deployment.yaml
kubectl apply -f k8s/alertmanager-service.yaml

# Deploy Webhook Receiver
kubectl apply -f k8s/webhook-receiver.yaml

# Restart Prometheus để load config mới
kubectl rollout restart deployment/prometheus
kubectl rollout restart deployment/alertmanager
```

### 3. Port-forward AlertManager (nếu cần)
```powershell
kubectl port-forward svc/alertmanager 9093:9093 --address 127.0.0.1
```

## Kiểm tra Status

### Xem Prometheus Targets
```
http://localhost:9090/targets
```

### Xem Alert Rules
```
http://localhost:9090/alerts
```

### Xem AlertManager
```
http://localhost:9093
```

### Xem Webhook Logs
```powershell
kubectl logs -f deployment/webhook-receiver
```

## Trigger Alert (Test)

### 1. CPU Alert (CPU > 80% trong 1 phút)
```powershell
# Chạy heavy load test trong 2 phút
./load-test-jmeter-style.ps1 -Duration 120 -Threads 50 -RequestsPerSecond 100
```

### 2. Memory Alert (nếu cần trigger)
Gửi requests tới endpoint `/create-large-object` (nếu có)

### 3. Xem Alert kích hoạt
```
http://localhost:9093/
```

## Cấu hình Email (SMTP Gmail)

1. Mở Gmail Account Settings
2. Bật 2FA
3. Tạo App Password: https://myaccount.google.com/apppasswords
4. Update trong `k8s/alertmanager-config.yaml`:
   ```yaml
   smtp_auth_username: 'your-email@gmail.com'
   smtp_auth_password: 'your-app-password'  # Không phải Gmail password
   ```

## Cấu hình Slack

1. Tạo Incoming Webhook: https://api.slack.com/messaging/webhooks
2. Update trong `k8s/alertmanager-config.yaml`:
   ```yaml
   slack_configs:
     - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
   ```

## Alert Channels

| Channel | Status | Config |
|---------|--------|--------|
| 📧 Email | ✅ Ready | `alertmanager-config.yaml` |
| 🔗 HTTP Webhook | ✅ Deployed | `webhook-receiver` service |
| 💬 Slack | 📝 Manual | Webhook URL |

## Example Alert Payload

```json
{
  "status": "firing",
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "HighCPUUsage",
        "severity": "critical",
        "pod": "springboot-k8s-xxxxx",
        "service": "springboot"
      },
      "annotations": {
        "summary": "🚨 High CPU Usage Detected",
        "description": "Pod springboot-k8s-xxxxx CPU usage is 85% (> 80%)",
        "dashboard": "http://localhost:3000/d/springboot-k8s"
      }
    }
  ]
}
```

## Troubleshooting

### Alerts không trigger
1. Kiểm tra Prometheus logs:
   ```powershell
   kubectl logs -f deployment/prometheus | Select-String "alert"
   ```

2. Kiểm tra alert rules:
   ```
   http://localhost:9090/alerts
   ```

### Webhook không nhận alert
1. Kiểm tra AlertManager logs:
   ```powershell
   kubectl logs -f deployment/alertmanager
   ```

2. Kiểm tra webhook receiver logs:
   ```powershell
   kubectl logs -f deployment/webhook-receiver
   ```

## Next Steps

- [ ] Configure Gmail SMTP credentials
- [ ] Configure Slack webhook URL
- [ ] Test CPU alert với load test
- [ ] Setup Grafana notification channel
- [ ] Create custom alert rules based on business metrics
