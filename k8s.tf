resource "azurerm_kubernetes_cluster" "gophersearch" {
  name                = "gophersearch"
  location            = "${azurerm_resource_group.default.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  dns_prefix          = "gophersearch"

  linux_profile {
    admin_username = "acctestuser1"

    ssh_key {
      key_data = "${tls_private_key.server.public_key_openssh}"
    }
  }

  agent_pool_profile {
    name            = "default"
    count           = 1
    vm_size         = "Standard_D1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

  tags {
    Environment = "dev"
  }
}
