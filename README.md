# microsoft-oss-conference
Example code for Microsoft Canada OSS conference

Work in Progress

Components:
Azure Kubernetes Cluster
Application provisioned to K8s
Bastion host to access DB, etc
Azure Managed Postgres
DNSimple DNS settings
Random provider for passwords
Dynamic Private Key generation
Output Variables
Input Variables
Remote Provisioners


## Environment variables
The following environment variables need to be set to your account values

```
export ARM_SUBSCRIPTION_ID="xxxxxxxxx"
export ARM_CLIENT_ID="xxxxxxxxx"
export ARM_CLIENT_SECRET="xxxxxxxxx"
export ARM_TENANT_ID="xxxxxxxxx"

export TF_VAR_client_id=$ARM_CLIENT_ID
export TF_VAR_client_secret=$ARM_CLIENT_SECRET

# FOR REMOTE STORAGE ACCOUNT
export ARM_ACCESS_KEY="xxxxxxxxx"
export REMOTE_STATE_ACCOUNT="xxxxxxxxxx"

# DNSimple
export DNSIMPLE_TOKEN=xxxxxxxx
export DNSIMPLE_ACCOUNT=xxxxxx
```

## TODO
[x] Complete configuration for basic app with K8s, Postgres
[x] Add remote state
[] Add Vault
[] Add Vault login for k8s
[] Provision dynamic credentials for Postgres
