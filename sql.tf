resource "random_string" "db_password" {
  length      = 16
  special     = false
  min_numeric = 5
}

resource "azurerm_postgresql_server" "gophersearch" {
  name                = "pgsql-${var.resource_group_name}"
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
  administrator_login_password = "${random_string.db_password.result}"
  version                      = "9.5"
  ssl_enforcement              = "Disabled"
}

resource "azurerm_postgresql_firewall_rule" "gophersearch" {
  name                = "office"
  resource_group_name = "${azurerm_resource_group.default.name}"
  server_name         = "${azurerm_postgresql_server.gophersearch.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_database" "gophersearch" {
  name                = "gophersearch"
  resource_group_name = "${azurerm_resource_group.default.name}"
  server_name         = "${azurerm_postgresql_server.gophersearch.name}"
  charset             = "UTF8"
  collation           = "English_United States.1252"

  connection {
    host        = "${azurerm_public_ip.jumpbox.fqdn}"
    user        = "azureuser"
    private_key = "${tls_private_key.server.private_key_pem}"
  }

  // Copy the files for setting up the database with defaults
  provisioner "file" {
    source      = "scripts/database.sql"
    destination = "/tmp/database.sql"
  }

  // Copy the initial data to the database
  provisioner "remote-exec" {
    inline = [
      "PGPASSWORD=${random_string.db_password.result} psql \"sslmode=disable host=${azurerm_postgresql_server.gophersearch.fqdn} port=5432 dbname=gophersearch\" --username=${var.db_user}@${azurerm_postgresql_server.gophersearch.name} < /tmp/database.sql",
    ]
  }
}
