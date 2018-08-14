resource "random_string" "jumpbox_password" {
  length  = 16
  special = false
}

resource "azurerm_public_ip" "jumpbox" {
  name                         = "jumpbox-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.default.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.resource_group_name}-ssh"
  depends_on                   = ["module.network"]

  tags {
    environment = "dev"
  }
}

resource "azurerm_network_security_group" "jumpbox" {
  name                = "jumpbox-ssh-access"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
}

resource "azurerm_network_security_rule" "ssh_access" {
  name                        = "ssh-access-rule"
  network_security_group_name = "${azurerm_network_security_group.jumpbox.name}"
  direction                   = "Inbound"
  access                      = "Allow"
  priority                    = 200
  source_address_prefix       = "*"
  source_port_range           = "*"
  destination_address_prefix  = "${azurerm_network_interface.jumpbox.private_ip_address}"
  destination_port_range      = "22"
  protocol                    = "TCP"
  resource_group_name         = "${azurerm_resource_group.default.name}"
}

resource "azurerm_network_interface" "jumpbox" {
  name                = "jumpbox-nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"

  ip_configuration {
    name                          = "IPConfiguration"
    subnet_id                     = "${module.network.vnet_subnets[0]}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jumpbox.id}"
  }

  tags {
    environment = "dev"
  }
}

resource "azurerm_virtual_machine" "jumpbox" {
  name                  = "jumpbox"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.default.name}"
  network_interface_ids = ["${azurerm_network_interface.jumpbox.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "jumpbox-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "jumpbox"
    admin_username = "${var.jumpbox_user}"
    admin_password = "${random_string.jumpbox_password.result}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = "${tls_private_key.server.public_key_openssh}"
    }
  }

  tags {
    environment = "dev"
  }

  connection {
    host        = "${azurerm_public_ip.jumpbox.fqdn}"
    user        = "azureuser"
    private_key = "${tls_private_key.server.private_key_pem}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y postgresql-client jq unzip apt-transport-https",
      "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
      "sudo touch /etc/apt/sources.list.d/kubernetes.list",
      "echo \"deb http://apt.kubernetes.io/ kubernetes-xenial main\" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt-get update",
      "sudo apt-get install -y kubectl",
      "curl --silent --location --output vault.zip https://releases.hashicorp.com/vault/${var.vault_version}/vault_${var.vault_version}_linux_amd64.zip",
      "unzip vault.zip",
      "sudo mv vault /usr/local/bin/vault",
      "rm vault.zip",
    ]
  }
}
