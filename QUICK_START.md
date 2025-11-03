# 🚀 QUICK START - Chạy ngay

## ⚡ 1 lệnh để chạy toàn bộ

```powershell
# Xây dựng
mvn clean package -DskipTests

# Build Docker image
docker build -t springboot-k8s:0.0.3 .

# Deploy tất cả
kubectl apply -f k8s/deployment.yaml k8s/service.yaml
kubectl apply -f k8s/prometheus-rbac.yaml k8s/prometheus-configmap.yaml k8s/prometheus-deployment.yaml k8s/prometheus-service.yaml
kubectl apply -f k8s/grafana-datasource.yaml k8s/grafana-deployment.yaml k8s/grafana-service.yaml k8s/grafana-dashboard.yaml

# Chờ pods khởi động
kubectl get pods -w
```

---

## 🖥️ Truy cập 3 cửa sổ

**Terminal 1 - Spring Boot App**
```powershell
kubectl port-forward svc/springboot-k8s 8080:80
# Mở: http://localhost:8080
```

**Terminal 2 - Prometheus**
```powershell
kubectl port-forward svc/prometheus 9090:9090
# Mở: http://localhost:9090
```

**Terminal 3 - Grafana**
```powershell
kubectl port-forward svc/grafana 3000:3000
# Mở: http://localhost:3000
# Login: admin / admin
```

**Terminal 4 (tùy chọn) - Tạo traffic**
```powershell
./test-load.ps1 -Duration 60 -Interval 1
```

---

## 📊 Khi truy cập Grafana sẽ thấy

4 biểu đồ real-time:
1. **JVM Heap Memory** - Memory usage
2. **CPU Usage %** - CPU hiện tại
3. **HTTP Requests/sec** - Traffic
4. **Active Threads** - Threads running

---

## 📖 Tài liệu

| File | Mục đích |
|------|---------|
| `README.md` | Hướng dẫn chính (tiếng Việt) |
| `00-SUMMARY_VI.md` | Tóm tắt toàn bộ |
| `GRAFANA_GUIDE_VI.md` | Chi tiết Grafana |
| `GRAFANA_VISUAL_VI.md` | Hình minh họa |
| `GRAFANA_RESULT_VI.md` | Kết quả khi chạy |

---

## ✨ **Thế đó!** ✨

Bạn có monitoring stack hoàn chỉnh cho K8s! 🎉
