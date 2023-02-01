#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


# This script is adpated to work with non-gke environments such as aks.
# Originally created by Seth Vargo (https://github.com/sethvargo). 
# Orignal script url: https://github.com/sethvargo/vault-kubernetes-workshop/blob/master/scripts/15-setup-vault-comms-k8s.sh
# Full credit goes to the author Seth Vargo (https://github.com/sethvargo).

source /tmp/output

if [ -z "${PG_USER}" ]; then
  echo "Missing PG_USER!"
  exit 1
fi

if [ -z "${PG_PASSWORD}" ]; then
  echo "Missing PG_PASSWORD!"
  exit 1
fi

if [ -z "${PG_DB_NAME}" ]; then
  echo "Missing PG_DB_NAME!"
  exit 1
fi

if [ -z "${PG_HOST}" ]; then
  echo "Missing PG_HOST!"
  exit 1
fi

if [ -z "${CLUSTER_NAME}" ]; then
  echo "Missing CLUSTER_NAME!"
  exit 1
fi

VAULT_INTERNAL_IP=""
while [ -z $VAULT_INTERNAL_IP ]; do
  echo "Waiting for end point..."
  VAULT_INTERNAL_IP=$(kubectl get service vault -o go-template='{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}')
  [ -z "$VAULT_INTERNAL_IP" ] && sleep 10
done
echo 'End point ready:' && echo $VAULT_INTERNAL_IP

# Configure Vault address and perform login
export VAULT_ADDR=http://${VAULT_INTERNAL_IP}:8200
vault login root

# Enable database secret engine
vault secrets enable database

# Configure Vault with postgres plugin information
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="grant-all" \
    connection_url="postgresql://{{username}}@${PG_DB_NAME}:{{password}}@${PG_HOST}:5432/gophersearch?sslmode=disable" \
    username="${PG_USER}" \
    password="${PG_PASSWORD}"

# Configure Vault role to run a sql query to create a database credential.
vault write database/roles/grant-all \
  db_name="postgresql" \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"

echo 'path "database/creds/grant-all" {
  capabilities = ["read", "list"]
}

path "secret/data/gophersearch" {
  capabilities = ["read", "list"]
}

path "sys/renew/*" {
  capabilities = ["update"]
}' | vault policy write db-readonly - 

# To generate an example postgres user and password pair try the following:
# vault read database/creds/grant-all
# Key                Value
# ---                -----
# lease_id           database/creds/grant-all/e382aaf0-0498-b903-605f-62bdc36f8251
# lease_duration     768h
# lease_renewable    true
# password           A1a-1j5Vb08Ilx9lMhla
# username           v-token-grant-al-hWrxltyZsKJyZcNMsPEA-1534802105

# Create Kubernetes service account for Vault to authenticate against
kubectl create serviceaccount vault-auth
kubectl apply -f - <<EOH
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: default
EOH

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

# Enable the Kubernetes authentication method
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

# Store postgres secrets for gophersearch
# Using Vault as a secret store for application data
vault kv put secret/gophersearch postgres_server_name=${PG_DB_NAME} postgres_server_fqdn=${PG_HOST}
