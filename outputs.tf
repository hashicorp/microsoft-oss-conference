output "bastion_host" {
  value = "${azurerm_public_ip.jumpbox.fqdn}"
}

# Create a simple output for ssh into the bastion host
# To use this run the following command from the project directory: 
# $(terraform output bastion_host_ssh)
output "bastion_host_ssh" {
  value = "ssh -q -i ${path.module}/.ssh/id_rsa -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o StrictHostKeyChecking=no ${var.jumpbox_user}@${azurerm_public_ip.jumpbox.fqdn}"
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.gophersearch.kube_config_raw}"
}

output "configure_kube_config" {
  value = "export KUBECONFIG=${path.module}/.kube/config"
}
