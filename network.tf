module "network" {
  source              = "Azure/network/azurerm"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
}
