# HOÀN THÀNH - Spring Boot K8s Monitoring Stack

## Tóm tắt công việc

Bạn vừa tạo một **Full Monitoring Stack** cho Spring Boot chạy trên Kubernetes:

- ✅ **Spring Boot App** - 2 replicas trên K8s
- ✅ **Prometheus** - Thu thập metrics
- ✅ **Grafana** - Hiển thị biểu đồ đẹp
- ✅ **AlertManager** 
---

## File và folder tạo ra

### **Java Source Code**
```
src/main/java/com/example/springbootk8s/
├── DemoApplication.java        # Main class
└── HelloController.java        # REST endpoint

src/main/resources/
└── application.properties      # Enable Prometheus metrics
```

### **Docker & Build**
```
pom.xml                         # Maven config + Micrometer
Dockerfile                      # Multi-stage build
target/
└── springboot-k8s-0.0.3.jar   # Executable JAR
```

### **Kubernetes - App**
```
k8s/deployment.yaml             # 2 replicas Spring Boot
k8s/service.yaml                # LoadBalancer service
```

### **Kubernetes - Prometheus**
```
k8s/prometheus-rbac.yaml        # ServiceAccount + RBAC
k8s/prometheus-configmap.yaml   # Scrape config
k8s/prometheus-deployment.yaml  # Prometheus pod
k8s/prometheus-service.yaml     # Prometheus service
```

### **Kubernetes - Grafana**
```
k8s/grafana-datasource.yaml     # Prometheus datasource
k8s/grafana-deployment.yaml     # Grafana pod
k8s/grafana-service.yaml        # Grafana service
k8s/grafana-dashboard.yaml      # Pre-built dashboard (4 biểu đồ)
```

### **Kubernetes - AlertManager**
```
k8s/alertmanager-config.yaml          # AlertManager config (SMTP, receivers)
k8s/alertmanager-deployment.yaml      # AlertManager pod
k8s/alertmanager-service.yaml         # AlertManager service
k8s/prometheus-rules.yaml              # Alert rules (CPU, Memory, Error, Restart)
k8s/prometheus-configmap-new.yaml     # Updated Prometheus config với alerting
k8s/prometheus-deployment-new.yaml    # Updated Prometheus deployment
k8s/webhook-receiver.yaml             # Webhook receiver K8s deployment
```

### **Tài liệu hướng dẫn**
```
README.md                           # Hướng dẫn chính (tiếng Việt)
GRAFANA_GUIDE_VI.md                # Chi tiết cách sử dụng Grafana
GRAFANA_VISUAL_VI.md               # Hình minh họa Grafana UI
GRAFANA_RESULT_VI.md               # Kết quả khi chạy Grafana
ALERTMANAGER_SETUP.md              # AlertManager setup chi tiết
ALERTMANAGER_SUMMARY_VI.md         # AlertManager tóm tắt
test-load.ps1                      # Script test load (normal)
load-test-jmeter-style.ps1        # Script test load (heavy - for alert)
webhook-receiver.py                # Flask app để receive alerts
Dockerfile.webhook                 # Docker image cho webhook receiver
```

---

## 🚀 Cách khởi chạy lại (nếu cần)

### **1. Build Java**
```powershell
mvn clean package -DskipTests
```

### **2. Build Docker Image**
```powershell
docker build -t springboot-k8s:0.0.3 .
```

### **3. Deploy lên Kubernetes**

#### Spring Boot App
```powershell
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

#### Prometheus
```powershell
kubectl apply -f k8s/prometheus-rbac.yaml
kubectl apply -f k8s/prometheus-configmap.yaml
kubectl apply -f k8s/prometheus-deployment.yaml
kubectl apply -f k8s/prometheus-service.yaml
```

#### Grafana
```powershell
kubectl apply -f k8s/grafana-datasource.yaml
kubectl apply -f k8s/grafana-deployment.yaml
kubectl apply -f k8s/grafana-service.yaml
kubectl apply -f k8s/grafana-dashboard.yaml
```

### **4. Port-forward để truy cập**

**Terminal 1 - Spring Boot App**
```powershell
kubectl port-forward svc/springboot-k8s 8080:80
# URL: http://localhost:8080
```

**Terminal 2 - Prometheus**
```powershell
kubectl port-forward svc/prometheus 9090:9090
# URL: http://localhost:9090
```

**Terminal 3 - Grafana**
```powershell
kubectl port-forward svc/grafana 3000:3000
# URL: http://localhost:3000
# Login: admin / admin
```

**Terminal 4 - Tạo load (tùy chọn)**
```powershell
./test-load.ps1 -Duration 60 -Interval 1
```

---

## Kiểm tra status

```powershell
# Kiểm tra tất cả pods
kubectl get pods

# Kiểm tra services
kubectl get svc

# Kiểm tra Spring Boot logs
kubectl logs deployment/springboot-k8s

# Kiểm tra Prometheus logs
kubectl logs deployment/prometheus

# Kiểm tra Grafana logs
kubectl logs deployment/grafana
```

---

## Khi bạn mở Grafana

Bạn sẽ thấy dashboard **"Spring Boot Kubernetes Monitoring"** với 4 biểu đồ:

1. **JVM Heap Memory Usage** - Memory sử dụng theo thời gian
2. **CPU Usage %** - CPU hiện tại
3. **HTTP Requests Per Second** - Traffic đến app
4. **Active Threads** - Threads đang chạy

**Chi tiết**: Xem file `GRAFANA_RESULT_VI.md`

---

## 🚨 AlertManager - Cảnh báo tự động

### **Đặc điểm**
Nhận cảnh báo **tự động** khi:
- 📊 **CPU > 80%** trong 1 phút → CRITICAL
- 💾 **Memory > 90%** trong 2 phút → WARNING
- ❌ **Error Rate > 5%** trong 5 phút → WARNING
- 🔄 **Pod Restart > 2 lần** trong 15 phút → CRITICAL

### **Hình thức thông báo**
- 📧 **Email** (Gmail SMTP)
- 🔗 **HTTP Webhook** (custom service)
- 💬 **Slack** (tùy chọn)

### **Cấu hình**
```powershell
# 1. Build webhook receiver image
docker build -f Dockerfile.webhook -t webhook-receiver:latest .

# 2. Deploy AlertManager
kubectl apply -f k8s/prometheus-rules.yaml
kubectl apply -f k8s/alertmanager-config.yaml
kubectl apply -f k8s/alertmanager-deployment.yaml
kubectl apply -f k8s/alertmanager-service.yaml
kubectl apply -f k8s/webhook-receiver.yaml

# 3. Update Prometheus
kubectl apply -f k8s/prometheus-configmap-new.yaml --force
kubectl apply -f k8s/prometheus-deployment-new.yaml --force
kubectl rollout restart deployment/prometheus
```

### **Port-forward AlertManager**
```powershell
kubectl port-forward svc/alertmanager 9093:9093 --address 127.0.0.1
# URL: http://localhost:9093
```

### **Test Alert - Trigger CPU**
```powershell
# Chạy heavy load test 90 giây
$url = "http://localhost:8080/"
$duration = 90
$threads = 30
$startTime = Get-Date
$endTime = $startTime.AddSeconds($duration)
while ((Get-Date) -lt $endTime) {
    for ($i = 0; $i -lt $threads; $i++) {
        Start-Job { Invoke-WebRequest $url } | Out-Null
    }
    Start-Sleep -Milliseconds 100
}
# CPU sẽ spike > 80% → Alert fires!
```

### **URLs Monitoring**
| Service | URL |
|---------|-----|
| Prometheus Alerts | http://localhost:9090/alerts |
| AlertManager | http://localhost:9093 |
| Webhook Receiver | http://localhost:5000/health |

### **Cấu hình Gmail Email**
1. Bật 2-Factor Authentication
2. Tạo App Password: https://myaccount.google.com/apppasswords
3. Update `k8s/alertmanager-config.yaml`:
```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'
```
4. Restart AlertManager:
```powershell
kubectl rollout restart deployment/alertmanager
```

### **Xem Alert Logs**
```powershell
# AlertManager logs
kubectl logs -f deployment/alertmanager

# Webhook receiver logs
kubectl logs -f deployment/webhook-receiver

# Prometheus alert rules
http://localhost:9090/alerts
```

**Chi tiết**: Xem file `ALERTMANAGER_SETUP.md` và `ALERTMANAGER_SUMMARY_VI.md`

---

## Dọn dẹp (nếu muốn xóa toàn bộ)

```powershell
# Xóa Spring Boot
kubectl delete deployment springboot-k8s
kubectl delete svc springboot-k8s

# Xóa Prometheus
kubectl delete deployment prometheus
kubectl delete svc prometheus
kubectl delete configmap prometheus-config prometheus-rules
kubectl delete sa prometheus
kubectl delete clusterrole prometheus
kubectl delete clusterrolebinding prometheus

# Xóa AlertManager
kubectl delete deployment alertmanager
kubectl delete svc alertmanager
kubectl delete configmap alertmanager-config

# Xóa Grafana
kubectl delete deployment grafana
kubectl delete svc grafana
kubectl delete configmap grafana-datasource grafana-dashboard grafana-dashboard-provisioner

# Xóa Webhook Receiver
kubectl delete deployment webhook-receiver
kubectl delete svc webhook-receiver

# Xóa Docker images
docker rmi springboot-k8s:0.0.3 webhook-receiver:latest prometheus:latest grafana/grafana:latest
```
---

## Đạt được gì

✅ **Monitoring**: Giám sát app real-time
✅ **Metrics**: JVM, CPU, Memory, HTTP, Threads
✅ **Visualization**: Dashboard đẹp trong Grafana
✅ **Alerting**: Cảnh báo tự động qua Email + Webhook + Slack
✅ **Scalable**: Có thể thêm nhiều metrics & alert rules
✅ **Production-ready**: RBAC, Health checks, Service discovery, Alert routing
✅ **DevOps Skills**: K8s, Docker, Prometheus, Grafana, AlertManager


## **Kết luận**

Đã có một **professional monitoring stack** hoàn chỉnh:
- Java app chạy trên K8s ✅
- Metrics được thu thập ✅
- Dashboard trực quan ✅
- Real-time monitoring ✅

