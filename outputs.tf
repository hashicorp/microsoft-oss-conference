output "bastion_ssh_private" {
  value = "${tls_private_key.server.private_key_pem}"
}

output "bastion_host" {
  value = "${azurerm_public_ip.jumpbox.fqdn}"
}

output "gophersearch_url" {
  value = "${kubernetes_service.gophersearch.load_balancer_ingress.0.ip}"
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.gophersearch.kube_config_raw}"
}
