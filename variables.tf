variable "resource_group_name" {
  description = "Name of the resource group to create"
  default     = "ms-oss-conference"
}

variable "location" {
  default = "westus"
}

variable "client_id" {
  description = "client_id from your Azure login settings, this can be set using an environment variable by prefixing the env var with TF_VAR_client_id"
}

variable "client_secret" {
  description = "client_secret from your Azure login settings, this can be set using an environment variable by prefixing the env var with TF_VAR_client_secret"
}

variable "db_user" {
  default = "psqladminun"
}

variable "db_pass" {
  default = "H@Sh1CoR3"
}

variable "jumpbox_user" {
  description = "remove this and use random string"
  default     = "azureuser"
}

variable "jumpbox_pass" {
  default = "Password1234!"
}
