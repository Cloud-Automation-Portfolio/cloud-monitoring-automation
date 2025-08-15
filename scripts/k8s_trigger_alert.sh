#!/bin/bash
# Trigger high CPU usage in Kubernetes pod to fire Prometheus/Grafana or Azure Monitor alerts

kubectl run stress --rm -i --tty --image=alpine -- sh -c "
  apk add --no-cache stress &&
  stress --cpu 2 --timeout 60
"
