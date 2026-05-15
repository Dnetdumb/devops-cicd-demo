```bash
# 1. Optimize Code and Pipeline 				                      -> nodejs/

# 2. Install and config Object Storage (MinIO)			          -> object-storage/

# 3. Install and config cluster CNPG Operator (CloudNativePG)	-> database/

# 4. Add LGTM stack						                                -> lgtm-stack/

# 5. Deploy app on K8s (Otel inject already)  			          -> k8s/

# 6. Install otel-collector 					                        -> otel-collector/
```
# 7. Observability Stack Overview

### 1. Add custom dashboard.json for nodejs-app
```bash
Grafana UI -> Dashboard -> New -> Import
```

### 2. Config "Derived fields" on "Loki Data Source"

<img width="2233" height="458" alt="attach9" src="https://github.com/user-attachments/assets/39aeeed8-c23c-4348-9d8a-a77a7b9d7d02" />


### 3. Grafana Dashboard for nodejs-app

<img width="2555" height="1385" alt="attach8" src="https://github.com/user-attachments/assets/d857c2a8-639d-4825-b1aa-e63f02bcc403" />

### 4. Application logs with traceID linked

<img width="2559" height="1376" alt="attach10" src="https://github.com/user-attachments/assets/16e50660-031f-409d-bc52-07ed5695a9b7" />

...

<img width="2559" height="1376" alt="attach11" src="https://github.com/user-attachments/assets/acd1ea6c-5387-48db-a96c-d913c6f82dbf" />

