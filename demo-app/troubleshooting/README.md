## "servicemonitor" and "prometheusrule" not show on prometheus.lab.local

#### Issues: Prometheus only scrape "servicemonitor" with "serviceMonitorSelector" and "prometheusrule" with "ruleSelector"

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
#### FIX: Edit file values.yaml, prometheusrule.yaml
```bash 
releaseLabel: monitoring -> releaseLabel: prometheus
release: monitoring 	 -> release: prometheus
```
## ArgoCD Image Updater not Updating
#### Issues: ArgoCD Image Updater Controller not detect any CRs (Custom Resource) and use "mode CRD" for default
```
kubectl logs -n argocd argocd-image-updater-controller-74b755db87-vnrxb

...
time="2026-03-26T09:43:44Z" level=info msg="No ImageUpdater CRs to process" controller=imageupdater controllerGroup=argocd-image-updater.>
...
```
#### FIX: Create an ImageUpdater with option "useAnnotations: true" to use "mode Annotations"
```bash
apiVersion: argocd-image-updater.argoproj.io/v1alpha1
kind: ImageUpdater
metadata:
  name: client-app-updater
  namespace: argocd
spec:
  applicationRefs:
    - namePattern: "client-app"
      useAnnotations: true
```
