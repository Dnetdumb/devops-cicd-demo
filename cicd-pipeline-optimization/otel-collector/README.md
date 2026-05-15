# Install and config Otel collector 

## Workflow:
```bash
			App (Otel SDK injected)
				| 	Metrics / Logs / Traces
				▼
		-------	Otel collector-----------
		|		|		|
		▼		▼		▼
	   Prometheus	       Loki 	      Tempo
	   (metrics)          (Logs)	     (Traces)
		|				|
		|				|
		--------------------------------
				|
				▼
			    Grafana
		(Dashboard, Metrics, Logs, TraceID)
```

## Deploy otel collector 
```bash
kubectl apply -f deploy-otel-collector.yaml

deployment.apps/otel-collector created
service/otel-collector created
```
## Add servicemonitor for scrape metrics from otel-collector
```bash
kubectl apply -f serviceMonitor-otel-Collector.yaml

servicemonitor.monitoring.coreos.com/otel-collector-monitor created
```

