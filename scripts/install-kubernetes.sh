#!/bin/bash
set -e

# Функция проверки установленного пакета
check_installed() {
    if dpkg -l "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Проверяем, установлены ли уже все необходимые компоненты
if check_installed "docker-ce" && \
   check_installed "kubelet" && \
   check_installed "kubeadm" && \
   check_installed "kubectl" && \
   systemctl is-active --quiet containerd && \
   systemctl is-active --quiet kubelet; then
    echo "Kubernetes components are already installed and running"
    exit 0
fi

# Обновляем систему
sudo apt-get update
sudo apt-get upgrade -y

# Устанавливаем необходимые пакеты
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Добавляем ключ Docker
if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
fi

# Добавляем репозиторий Docker
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# Добавляем ключ Kubernetes
if [ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]; then
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
fi

# Добавляем репозиторий Kubernetes
if [ ! -f /etc/apt/sources.list.d/kubernetes.list ]; then
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
fi

# Обновляем индекс пакетов
sudo apt-get update

# Устанавливаем Docker если не установлен
if ! check_installed "docker-ce"; then
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Устанавливаем Kubernetes если не установлен
if ! check_installed "kubelet" || ! check_installed "kubeadm" || ! check_installed "kubectl"; then
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
fi

# Настраиваем containerd
if [ ! -f /etc/modules-load.d/containerd.conf ]; then
    cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter
fi

# Настраиваем системные параметры для Kubernetes
if [ ! -f /etc/sysctl.d/99-kubernetes-cri.conf ]; then
    cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

    sudo sysctl --system
fi

# Настраиваем containerd если не настроен
if [ ! -f /etc/containerd/config.toml ]; then
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
fi

# Перезапускаем сервисы только если они не запущены или была изменена конфигурация
if ! systemctl is-active --quiet containerd; then
    sudo systemctl restart containerd
    sudo systemctl enable containerd
fi

if ! systemctl is-active --quiet kubelet; then
    sudo systemctl enable kubelet
fi

echo "Installation completed successfully" 