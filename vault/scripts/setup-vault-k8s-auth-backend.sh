#!/bin/bash
# This script is adpated to work with non-gke environments such as aks.
# Originally created by Seth Vargo (https://github.com/sethvargo). 
# Orignal script url: https://github.com/sethvargo/vault-kubernetes-workshop/blob/master/scripts/15-setup-vault-comms-k8s.sh
# Full credit goes to the author Seth Vargo (https://github.com/sethvargo).

if [ -z "${CLUSTER_NAME}" ]; then
  echo "Missing CLUSTER_NAME!"
  exit 1
fi

# Get the name of the secret corresponding to the service account
SECRET_NAME="$(kubectl get serviceaccount vault-auth \
  -o go-template='{{ (index .secrets 0).name }}')"

# Get the actual token reviewer account
TR_ACCOUNT_TOKEN="$(kubectl get secret ${SECRET_NAME} \
  -o go-template='{{ .data.token }}' | base64 --decode)"

# Get the host for the cluster (IP address)
K8S_HOST="$(kubectl config view --raw \
  -o go-template="{{ range .clusters }}{{ if eq .name \"${CLUSTER_NAME}\" }}{{ index .cluster \"server\" }}{{ end }}{{ end }}")"

# Get the CA for the cluster
K8S_CACERT="$(kubectl config view --raw \
  -o go-template="{{ range .clusters }}{{ if eq .name \"${CLUSTER_NAME}\" }}{{ index .cluster \"certificate-authority-data\" }}{{ end }}{{ end }}" | base64 --decode)"

# Enable the Kubernetes auth method
vault auth enable kubernetes

# Configure Vault to talk to our Kubernetes host with the cluster's CA and the
# correct token reviewer JWT token
vault write auth/kubernetes/config \
  kubernetes_host="${K8S_HOST}" \
  kubernetes_ca_cert="${K8S_CACERT}" \
  token_reviewer_jwt="${TR_ACCOUNT_TOKEN}"

# Create Vault app role
vault write auth/kubernetes/role/gopher \
  bound_service_account_names=default \
  bound_service_account_namespaces=default \
  policies=default,db-readonly \
  ttl=15m
