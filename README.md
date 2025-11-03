# Spring Boot chạy trên Kubernetes — Ví dụ đơn giản

Ứng dụng Spring Boot tối thiểu chạy trên Kubernetes với monitoring bằng Prometheus và Grafana.

## Project Structure

```
ptuddn-assignment/
├── pom.xml                           # Maven config (Spring Boot 3.1.6, Java 17)
├── Dockerfile                        # Multi-stage build
├── src/main/
│   ├── java/
│   │   └── com/example/springbootk8s/
│   │       ├── DemoApplication.java  # Main app class
│   │       └── HelloController.java  # REST endpoint
│   └── resources/
│       └── application.properties    # Actuator + Prometheus config
└── k8s/
    ├── deployment.yaml               # K8s Deployment (2 replicas)
    ├── service.yaml                  # K8s Service (LoadBalancer)
    ├── prometheus-configmap.yaml     # Prometheus scrape config
    ├── prometheus-deployment.yaml    # Prometheus deployment
    ├── prometheus-service.yaml       # Prometheus service
    └── prometheus-rbac.yaml          # RBAC for Prometheus
```

## Quick Start

### 1. Build the JAR 

```powershell
mvn clean package -DskipTests
# Output: target/springboot-k8s-0.0.1-SNAPSHOT.jar (built successfully)
```

### 2. Build the Docker image

docker build -t springboot-k8s:0.0.1 .

### 3. Deploy to Kubernetes

```powershell
# Apply Deployment and Service
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Watch pods starting up
kubectl get pods -w

# Get service info
kubectl get svc springboot-k8s
```

### 4. Access the app

**Cloud cluster (AWS, GCP, Azure):**
```powershell
kubectl get svc springboot-k8s
# Copy the EXTERNAL-IP and visit: http://<EXTERNAL-IP>
```

**Minikube:**
```powershell
minikube service springboot-k8s --url
# This opens the service URL automatically
```

**Local port-forward (any cluster):**
```powershell
kubectl port-forward svc/springboot-k8s 8080:80
# Visit: http://localhost:8080
```

## Endpoints

- `GET /` — Returns "Hello from Spring Boot on K8s — <timestamp>"
- `GET /actuator/health` — Health check (used by K8s liveness probe)
- `GET /actuator/prometheus` — Prometheus metrics endpoint

## Monitoring with Prometheus

### Deploy Prometheus:

```powershell
kubectl apply -f k8s/prometheus-rbac.yaml
kubectl apply -f k8s/prometheus-configmap.yaml
kubectl apply -f k8s/prometheus-deployment.yaml
kubectl apply -f k8s/prometheus-service.yaml

# Check Prometheus pod
kubectl get pods -l app=prometheus
```

### Access Prometheus:

```powershell
# Port-forward Prometheus
kubectl port-forward svc/prometheus 9090:9090

# Open browser: http://localhost:9090
```

**In Prometheus UI:**
- Go to "Status" → "Targets" to see Spring Boot scrape status
- Query metrics (e.g., `jvm_memory_used_bytes`, `http_requests_total`, etc.)
- Example queries:
  ```
  jvm_memory_used_bytes
  http_server_requests_seconds_count
  process_cpu_usage
  ```

## How it works

1. **Java**: Spring Boot 3.1.6 with Spring Web and Actuator
2. **Docker**: Multi-stage build
   - Stage 1: Maven 3.9.4 + JDK 17 → compile & package
   - Stage 2: Eclipse Temurin JRE 17 → lightweight runtime
3. **Kubernetes**: 
   - Deployment with 2 replicas
   - Service type LoadBalancer (change to NodePort if needed)
   - Readiness probe: `GET /`
   - Liveness probe: `GET /actuator/health`

## Notes

- The image is ~280MB (JRE 17 + app)
- Deployment waits 5s before checking readiness, then every 10s
- Liveness probe waits 30s before first check (let app warm up)
- If using Minikube, update `k8s/deployment.yaml` line 22 to `imagePullPolicy: Never`

## Cleanup

```powershell
# Remove app
kubectl delete deployment springboot-k8s
kubectl delete svc springboot-k8s

# Remove Prometheus
kubectl delete deployment prometheus
kubectl delete svc prometheus
kubectl delete configmap prometheus-config
kubectl delete sa prometheus
kubectl delete clusterrole prometheus
kubectl delete clusterrolebinding prometheus

# Remove Docker container
docker rm -f springboot-k8s-container
```

## Troubleshooting

**Pods stuck in ImagePullBackOff?**
- If not pushing to Docker Hub, ensure image is built into your cluster
- For Minikube: re-run `minikube docker-env | Invoke-Expression` and rebuild

**Pod crashes?**
```powershell
kubectl logs deployment/springboot-k8s
```

**Can't connect to service?**
```powershell
# Check if LoadBalancer has an external IP (may be <pending> on local clusters)
kubectl get svc springboot-k8s
# Use port-forward as workaround
kubectl port-forward svc/springboot-k8s 8080:80
```

---

**Next steps:**
- Add CI/CD (GitHub Actions)
- Add ConfigMaps for application.properties
- Add Ingress for HTTP routing
- Scale to more replicas or add HPA (Horizontal Pod Autoscaler)