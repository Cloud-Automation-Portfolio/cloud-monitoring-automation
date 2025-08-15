#!/bin/bash
# Destroy all lab resources

# AWS
cd stacks/aws
terraform destroy -auto-approve

# Azure VM
cd ../azure
terraform destroy -auto-approve

# AKS
cd ../k8s
terraform destroy -auto-approve

# Prometheus & Grafana cleanup
kubectl delete namespace monitoring
