# microsoft-oss-conference
Example code for Microsoft Canada OSS conference

Work in Progress

## Components
* Azure Kubernetes Cluster
* Application provisioned to K8s
* Bastion host to access DB, etc
* Azure Managed Postgres
* DNSimple DNS settings
* Random provider for passwords
* Dynamic Private Key generation
* Output Variables
* Input Variables
* Remote Provisioners


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

## Setup

* Follow the [instructions](https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html#creating-a-service-principal-using-the-azure-cli) to create a service principle required to supply `client_id` and `client_secret` to Terraform.

## Usage

Terraform commands

```bash
terraform init
terraform plan
terraform apply
```

### Accessing the bastion host

```bash
$(terraform output bastion_host_ssh)
```

### Accessing the Kubernetes cluster

```bash
$(terraform output configure_kube_config)
```

```bash
kubectl get nodes
```

Expected output

```bash
TODO
```

## TODO
- [x] Complete configuration for basic app with K8s, Postgres.
- [x] Add remote state.
- [x] Add Vault.
- [x] Add Vault login for k8s.
- [x] Provision dynamic credentials for Postgres via Consul Template.
- [ ] Add a configmap for gophersearch `DATABASE_URL` (use environment variable in the kubernetes deployment configuration).



