# HOÀN THÀNH - Spring Boot K8s Monitoring Stack

## Tóm tắt công việc

Đã tạo một **Full Monitoring Stack** cho Spring Boot chạy trên Kubernetes:

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
<img width="1004" height="428" alt="image" src="https://github.com/user-attachments/assets/695ba873-3908-4d43-89d9-37477a02e1f1" />


**Terminal 2 - Prometheus**
```powershell
kubectl port-forward svc/prometheus 9090:9090
# URL: http://localhost:9090
```
<img width="1004" height="381" alt="image" src="https://github.com/user-attachments/assets/f8ebe571-0e41-4f95-bbc8-4f38ff064d43" />


**Terminal 3 - Grafana**
```powershell
kubectl port-forward svc/grafana 3000:3000
# URL: http://localhost:3000
# Login: admin / admin
```
<img width="1783" height="958" alt="image" src="https://github.com/user-attachments/assets/c767d923-0665-4c77-a9ce-8c66ddd34f3b" />


**Terminal 4 - Tạo load (tùy chọn)**
```powershell
./test-load.ps1 -Duration 60 -Interval 1
```

---

##  AlertManager - Cảnh báo tự động

### **Đặc điểm**
Nhận cảnh báo **tự động** khi:
-  **CPU > 80%** trong 1 phút → CRITICAL
-  **Memory > 90%** trong 2 phút → WARNING
-  **Error Rate > 5%** trong 5 phút → WARNING
-  **Pod Restart > 2 lần** trong 15 phút → CRITICAL
<img width="1825" height="744" alt="image" src="https://github.com/user-attachments/assets/f567531b-130c-46a9-9c77-7e6f4455da7a" />


### **Hình thức thông báo**
-  **Email** (Gmail SMTP)

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
   <img width="1200" height="211" alt="image" src="https://github.com/user-attachments/assets/09cac215-af46-4483-a98c-5c04eab1930f" />

2. Tạo App Password: https://myaccount.google.com/apppasswords
   <img width="991" height="724" alt="image" src="https://github.com/user-attachments/assets/dd70f277-1d1d-44fa-8c7c-abb7b074bc35" />

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

## **Kết luận**

Đã có một **professional monitoring stack** hoàn chỉnh:
- Java app chạy trên K8s ✅
- Metrics được thu thập ✅
- Dashboard trực quan ✅
- Real-time monitoring ✅

