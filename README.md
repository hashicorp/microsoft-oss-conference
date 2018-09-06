# Microsoft OSS Conference Presentation

Terraform configuration and Kubernetes manifests used for Microsoft Canada OSS conference presentation.

## Prerequisites

* Install [Terraform](https://terraform.io/downloads.html).
* An [Azure Account](https://azure.microsoft.com/en-ca/free/).

## Setup

* Clone the Github repository

```bash
git clone https://github.com/hashicorp/microsoft-oss-conference.git
```

* Follow the [instructions](https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html#creating-a-service-principal-using-the-azure-cli) to create a service principal required to supply `client_id` and `client_secret` to Terraform.

* Export the following environment variables

```bash
export ARM_SUBSCRIPTION_ID="xxxxxxxxx"
export ARM_CLIENT_ID="xxxxxxxxx"
export ARM_CLIENT_SECRET="xxxxxxxxx"
export ARM_TENANT_ID="xxxxxxxxx"

export TF_VAR_client_id=$ARM_CLIENT_ID
export TF_VAR_client_secret=$ARM_CLIENT_SECRET
```

## Usage

Switch to the "microsoft-oss-conference" directory

```bash
cd microsoft-oss-conference
```

Run Terraform init and plan

```bash
terraform init
terraform plan
```

Expected output

```bash

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  + azurerm_kubernetes_cluster.gophersearch
.....
  + module.network.azurerm_virtual_network.vnet
      id:                                                                 <computed>
      address_space.#:                                                    "1"
      address_space.0:                                                    "10.0.0.0/16"
      location:                                                           "westus"
      name:                                                               "acctvnet"
      resource_group_name:                                                "ms-oss"
      subnet.#:                                                           <computed>
      tags.%:                                                             "2"
      tags.tag1:                                                          <computed>
      tags.tag2:                                                          <computed>


Plan: 21 to add, 0 to change, 0 to destroy.
```

Run Terraform apply

```bash
terraform apply
```

```bash
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
```

*Note: This might take up to 15-18 minutes to complete.*

Expected output

```bash
tls_private_key.server: Creating...
  algorithm:          "" => "RSA"
  ecdsa_curve:        "" => "P224"
  private_key_pem:    "" => "<computed>"
  public_key_openssh: "" => "<computed>"
  public_key_pem:     "" => "<computed>"
  rsa_bits:           "" => "4096"
random_string.jumpbox_password: Creating...
.....
null_resource.provision-workload: Still creating... (30s elapsed)
null_resource.provision-workload (remote-exec): Waiting for end point...
null_resource.provision-workload: Still creating... (40s elapsed)
null_resource.provision-workload (remote-exec): Waiting for end point...
null_resource.provision-workload (remote-exec): End point ready:
null_resource.provision-workload (remote-exec): 10.0.2.35
null_resource.provision-workload (remote-exec): Success! You are now authenticated. The token information displayed below
null_resource.provision-workload (remote-exec): is already stored in the token helper. You do NOT need to run "vault login"
null_resource.provision-workload (remote-exec): again. Future Vault requests will automatically use this token.
null_resource.provision-workload (remote-exec):
null_resource.provision-workload (remote-exec): Key                  Value
null_resource.provision-workload (remote-exec): ---                  -----
null_resource.provision-workload (remote-exec): token                root
null_resource.provision-workload (remote-exec): token_accessor       04c3dfbd-6546-2f93-4a7b-8b5db0487bc5
null_resource.provision-workload (remote-exec): token_duration       ∞
null_resource.provision-workload (remote-exec): token_renewable      false
null_resource.provision-workload (remote-exec): token_policies       ["root"]
null_resource.provision-workload (remote-exec): identity_policies    []
null_resource.provision-workload (remote-exec): policies             ["root"]
null_resource.provision-workload (remote-exec): Success! Enabled the database secrets engine at: database/
null_resource.provision-workload (remote-exec): Success! Data written to: database/roles/grant-all
null_resource.provision-workload (remote-exec): Success! Uploaded policy: db-readonly
null_resource.provision-workload (remote-exec): serviceaccount/vault-auth created
null_resource.provision-workload (remote-exec): clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
null_resource.provision-workload (remote-exec): Success! Enabled kubernetes auth method at: kubernetes/
null_resource.provision-workload (remote-exec): Success! Data written to: auth/kubernetes/config
null_resource.provision-workload (remote-exec): Success! Data written to: auth/kubernetes/role/gopher
null_resource.provision-workload (remote-exec): Key              Value
null_resource.provision-workload (remote-exec): ---              -----
null_resource.provision-workload (remote-exec): created_time     2018-09-06T05:26:47.32793751Z
null_resource.provision-workload (remote-exec): deletion_time    n/a
null_resource.provision-workload (remote-exec): destroyed        false
null_resource.provision-workload (remote-exec): version          1
null_resource.provision-workload: Creation complete after 49s (ID: 5680440717165316042)

Apply complete! Resources: 21 added, 0 changed, 0 destroyed.

Outputs:
.....
```

Accessing the Kubernetes cluster

```bash
$(terraform output configure_kube_config)
```

Validate the Kubernetes cluster

```bash
kubectl get nodes
```

Expected output

```bash
NAME                     STATUS    ROLES     AGE       VERSION
aks-default-40738537-0   Ready     agent     8m        v1.9.9
```

List pods and validate the `vault-x` pod is running

```bash
kubectl get pods
```

Expected output

```bash
NAME                     READY     STATUS    RESTARTS   AGE
vault-78dd95957b-cgmzj   1/1       Running   0          4m
```

Deploy the gophersearch application on Kubernetes

```bash
kubectl apply -f kubernetes/gophersearch-vault-sidecar.yaml
```

Expected output

```bash
pod "gophersearch-vault-sidecar" created
service "gophersearch" created
```

Validate whether it is running on Kubernetes

```bash
kubectl get pods | grep gophersearch
```

Expected output

```bash
gophersearch-vault-sidecar   2/2       Running   0          20s
```

Test the gophersearch application locally

```bash
kubectl port-forward gophersearch-vault-sidecar 3000:3000
```

Open the application in the browser

```bash
open http://localhost:3000
```

Validate the Kubernetes service is ready

```bash
kubectl get service | grep gophersearch
```

Expected output

```bash
gophersearch   LoadBalancer   10.2.0.242   104.42.156.101   80:30267/TCP     8m
```

Open the application in the browser

```bash
open http://104.42.156.101
```

### Accessing the bastion host

```bash
$(terraform output bastion_host_ssh)
```

### Configuring Kubernetes client

```bash
$(terraform output configure_kube_config)
```

