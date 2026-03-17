# "servicemonitor" and "prometheusrule" not show on prometheus.lab.local

The problem is: Prometheus only scrape "servicemonitor" with "serviceMonitorSelector" and "prometheusrule" with "ruleSelector"

```bash
 kubectl get prometheus -A
NAMESPACE    NAME                                    VERSION   DESIRED   READY   RECONCILED   AVAILABLE   AGE
monitoring   prometheus-kube-prometheus-prometheus   v3.10.0   1         1       True         True        3d18h
 kubectl get prometheus prometheus-kube-prometheus-prometheus -n monitoring -oyaml 
...
serviceMonitorSelector:
    matchLabels:
      release: prometheus
...

ruleSelector:
    matchLabels:
      release: prometheus
...
```
FIX:
```bash
Edit file values.yaml, prometheusrule.yaml: 
releaseLabel: monitoring -> releaseLabel: prometheus
release: monitoring 	 -> release: prometheus
```
