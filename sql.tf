resource "azurerm_postgresql_server" "test" {
  name                = "postgresql-server-${var.resource_group_name}"
  location            = "westus"
  resource_group_name = "${azurerm_resource_group.default.name}"

  sku {
    name     = "B_Gen4_2"
    capacity = 2
    tier     = "Basic"
    family   = "Gen4"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "${var.db_user}"
  administrator_login_password = "${var.db_pass}"
  version                      = "9.5"
  ssl_enforcement              = "Enabled"
}

resource "azurerm_postgresql_database" "test" {
  name                = "gophersearch"
  resource_group_name = "${azurerm_resource_group.default.name}"
  server_name         = "${azurerm_postgresql_server.test.name}"
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "null_resource" "db" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${join(",", azurerm_postgresql_database.test.*.id)}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host        = "${azurerm_public_ip.jumpbox.fqdn}"
    user        = "azureuser"
    private_key = "${tls_private_key.server.private_key}"
  }

  // Copy the files for setting up the database with defaults
  provisioner "file" {
    source      = "scripts/configure_db.sh"
    destination = "/tmp/configure_db.sh"
  }

  provisioner "file" {
    source      = "scripts/database.sql"
    destination = "/tmp/database.sql"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the clutser
    inline = [
      "chmod +x /tmp/configure_db.sh",
      "./configure_db.sh ${azurerm_postgresql_server.test.fqdn} ${azurerm_postgresql_server.test.name}@${var.db_user} ${var.db_pass}",
    ]
  }
}
