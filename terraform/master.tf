resource "ssh_resource" "install_kubernetes_master" {
  host        = var.master_ip
  user        = var.ssh_user
  private_key = file(var.ssh_private_key)

  file {
    source      = "${path.module}/../scripts/install-kubernetes.sh"
    destination = "/tmp/install-kubernetes.sh"
  }

  file {
    source      = "${path.module}/../scripts/init-master.sh" 
    destination = "/tmp/init-master.sh"
  }

  commands = [
    "chmod +x /tmp/install-kubernetes.sh",
    "chmod +x /tmp/init-master.sh",
    "/tmp/install-kubernetes.sh",
    "/tmp/init-master.sh",
    "rm /tmp/install-kubernetes.sh",
    "rm /tmp/init-master.sh"
  ]
}

output "join_command" {
  value     = ssh_resource.install_kubernetes_master.result
  sensitive = true
}