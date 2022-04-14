#!/bin/bash
kubectl get secret prometheus-stack-grafana -n prometheus -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
