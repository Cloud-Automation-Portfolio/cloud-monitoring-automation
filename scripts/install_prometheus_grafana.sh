#!/bin/bash
# Install Prometheus & Grafana on AKS using Helm

kubectl create namespace monitoring

# Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus \
  -n monitoring \
  -f prometheus-values.yaml

# Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana \
  -n monitoring \
  --set persistence.enabled=false \
  --set adminPassword='admin' \
  --set service.type=ClusterIP
