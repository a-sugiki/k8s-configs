#!/bin/bash
kubectl patch svc -n prometheus prometheus-stack-grafana -p '{"spec": {"type": "ClusterIP"}}'
