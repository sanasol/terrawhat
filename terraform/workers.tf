resource "ssh_resource" "install_kubernetes_workers" {
  count       = length(var.worker_ips)
  host        = var.worker_ips[count.index]
  user        = var.ssh_user
  private_key = file(var.ssh_private_key)

  file {
    source      = "${path.module}/../scripts/install-kubernetes.sh"
    destination = "/tmp/install-kubernetes.sh"
  }

  file {
    source      = "${path.module}/../scripts/join-cluster.sh"
    destination = "/tmp/join-cluster.sh"
  }

  commands = [
    "chmod +x /tmp/install-kubernetes.sh",
    "chmod +x /tmp/join-cluster.sh",
    "/tmp/install-kubernetes.sh",
    "/tmp/join-cluster.sh '${data.external.kubeadm_join_command.result["command"]}'",
    "rm /tmp/install-kubernetes.sh",
    "rm /tmp/join-cluster.sh"
  ]

  depends_on = [ssh_resource.install_kubernetes_master]
}

data "external" "kubeadm_join_command" {
  program = ["sh", "-c", "ssh -i ${var.ssh_private_key} ${var.ssh_user}@${var.master_ip} 'sudo kubeadm token create --print-join-command' | jq -R '{command: .}'"]

  depends_on = [ssh_resource.install_kubernetes_master]
}