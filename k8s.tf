# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

resource "azurerm_kubernetes_cluster" "gophersearch" {
  name                = "gophersearch"
  location            = "${azurerm_resource_group.default.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  dns_prefix          = "gophersearch"

  linux_profile {
    admin_username = "azureuser"

    ssh_key {
      key_data = "${tls_private_key.server.public_key_openssh}"
    }
  }

  agent_pool_profile {
    name            = "default"
    count           = 1
    vm_size         = "Standard_DS2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30

    # Required for advanced networking
    # we are using a subnet that is different from the jumpbox.
    vnet_subnet_id = "${module.network.vnet_subnets[1]}"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

  # Advanced networking
  network_profile {
    network_plugin     = "azure"
    docker_bridge_cidr = "172.17.0.1/16"
    dns_service_ip     = "10.2.0.10"
    service_cidr       = "10.2.0.0/24"
  }

  tags {
    Environment = "dev"
  }
}

resource "null_resource" "save-kube-config" {
  triggers {
    config = "${azurerm_kubernetes_cluster.gophersearch.kube_config_raw}"
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.kube
      echo "${azurerm_kubernetes_cluster.gophersearch.kube_config_raw}" > ${path.module}/.kube/config
      chmod 0600 ${path.module}/.kube/config
EOF
  }
}

resource "null_resource" "provision-workload" {
  # Changes to aks cluster requires re-provisioning
  triggers {
    config = "${azurerm_kubernetes_cluster.gophersearch.kube_config_raw}"
  }

  connection {
    host        = "${azurerm_public_ip.jumpbox.fqdn}"
    user        = "azureuser"
    private_key = "${tls_private_key.server.private_key_pem}"
  }

  // Create directories required for using Kubernetes
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/kubernetes",
      "mkdir -p /home/azureuser/.kube",
    ]
  }

  // Copy the all Kubernetes manifests along with a few scripts to install
  // and configure vault.
  provisioner "file" {
    source      = "kubernetes/"
    destination = "/tmp/kubernetes"
  }

  // Write Kubernetes config file
  provisioner "remote-exec" {
    inline = [
      "echo \"${azurerm_kubernetes_cluster.gophersearch.kube_config_raw}\" > /home/azureuser/.kube/config",
    ]
  }

  // Setup Vault on kubernetes
  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f /tmp/kubernetes/vault.yaml",
      "sleep 20",
      "sudo chmod 755 /tmp/kubernetes/scripts/vault-dynamic-secret-setup.sh",
      "echo '#!/bin/bash\nexport PG_USER=\"${var.db_user}\"\nexport PG_PASSWORD=\"${random_string.db_password.result}\"\nexport PG_DB_NAME=\"${azurerm_postgresql_server.gophersearch.name}\"\nexport PG_HOST=\"${azurerm_postgresql_server.gophersearch.fqdn}\"\nexport CLUSTER_NAME=\"${azurerm_kubernetes_cluster.gophersearch.name}\"' > /tmp/output",
      "sudo chmod 755 /tmp/output",
      "/tmp/kubernetes/scripts/vault-dynamic-secret-setup.sh",
    ]
  }
}
