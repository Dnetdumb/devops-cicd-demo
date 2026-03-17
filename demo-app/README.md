# Create an App to Generate Metrics

### Idea:

The application metrics-app is the main service. It provides the following APIs:
```bash
/api/user
/api/order
/api/payment
```
Whenever requests are sent to these APIs, the application records:
```bash
Total number of requests
Response time
Response status
```
The application exposes metrics at the endpoint:
```bash
/metrics
```
#### Build and Run the Main App (`metrics-app`)
Build the Docker image and push it to Docker Hub
```bash
docker build -t peidhhn/metrics-app:latest -f Dockerfile.main .
docker push -t peidhhn/metrics-app:latest
```

#### Deploy the Main App
Deploy it to the namespace `appteam1`:
```
kubectl apply -f main.deployment.yaml -n appteam1 --create-namspace
```

#### Build and Run the Client App
Build docker image and push to docker hub
```bash
docker build -t peidhhn/client-app:latest -f Dockerfile.client .
docker push -t peidhhn/client-app:latest
```

#### Deploy the Client App
Deploy it to the same namespace `appteam1`
```bash 
kubectl apply -f client.deployment.yaml -n appteam1 --create-namespace
```

#### Create a Dashboard to Monitor Metrics
We can import the file "main.dashboard.exported.json" directly into Grafana to create a dashboard for monitoring the application's metrics.

#### Update "prometheusrule" for metrics-app 
```bash
kubectl apply -f prometheus-rule.yaml
```
Check:
```bash
get prometheusrule -n appteam1
NAME                AGE
metrics-app-rules   31s
```

## Demo with Jenkinsfiles:

#### Jenkins Pipeline Flow:
```bash
Checkout Code
      │
      ▼
Build Docker Images
      │
      ▼
Trivy security scan	← Optional
      │
      ▼
Push DockerHub
      │
      ▼
Manual Approval
      │
      ▼
Deploy Kubernetes
      │
      ▼
Update Images
      │
      ▼
Verify Rollout		← make sure pod running
      │
      ▼
Endpoint Test		← check service/pod
      │
      ▼
Pipeline Success
```

