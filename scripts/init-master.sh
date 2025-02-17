#!/bin/bash
set -e

# Проверяем, инициализирован ли уже мастер
if [ -f /etc/kubernetes/admin.conf ]; then
    echo "Master node is already initialized"
    kubeadm token create --print-join-command
    exit 0
fi

# Инициализируем мастер-ноду
kubeadm init --pod-network-cidr=10.244.0.0/16

# Настраиваем kubectl для root
export KUBECONFIG=/etc/kubernetes/admin.conf

# Устанавливаем сетевой плагин (Flannel)
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Устанавливаем Metrics Server для HPA
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Выводим команду для присоединения
kubeadm token create --print-join-command
