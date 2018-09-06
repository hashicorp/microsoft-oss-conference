provider "azurerm" {}

// Create a private key for the bastion host and k8s
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

// Save the private key locally in the root directory of the project 
// rather than using an output variable to access it.
resource "null_resource" "save-key" {
  triggers {
    key = "${tls_private_key.server.private_key_pem}"
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${path.module}/.ssh
      echo "${tls_private_key.server.private_key_pem}" > ${path.module}/.ssh/id_rsa
      chmod 0600 ${path.module}/.ssh/id_rsa
EOF
  }
}

resource "azurerm_resource_group" "default" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags {
    environment = "dev"
  }
}
