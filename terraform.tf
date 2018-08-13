// Remote state config
terraform {
  backend "azurerm" {
    storage_account_name = "nictfremotestate"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

provider "azurerm" {}

provider "kubernetes" {
  host                   = "${azurerm_kubernetes_cluster.gophersearch.kube_config.0.host}"
  username               = "${azurerm_kubernetes_cluster.gophersearch.kube_config.0.username}"
  password               = "${azurerm_kubernetes_cluster.gophersearch.kube_config.0.password}"
  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.gophersearch.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.gophersearch.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.gophersearch.kube_config.0.cluster_ca_certificate)}"
}

provider "dnsimple" {}

// Create a private key for the bastion host and k8s
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_resource_group" "default" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags {
    environment = "dev"
  }
}
