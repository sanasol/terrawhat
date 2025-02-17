terraform {
  required_providers {
    ssh = {
      source  = "loafoe/ssh"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

variable "master_ip" {
  type        = string
  description = "IP адрес мастер-узла"
}

variable "worker_ips" {
  type        = list(string)
  description = "Список IP адресов рабочих узлов"
}

variable "ssh_private_key" {
  type        = string
  description = "Путь к приватному SSH ключу"
}

variable "ssh_user" {
  type        = string
  description = "Пользователь SSH"
  default     = "debian"
} 