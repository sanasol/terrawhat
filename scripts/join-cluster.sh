#!/bin/bash
set -e

# Проверяем, является ли нода уже частью кластера
if [ -f /etc/kubernetes/kubelet.conf ] && [ -f /etc/kubernetes/pki/ca.crt ]; then
    echo "Node is already part of the cluster"
    exit 0
fi

# Выполняем команду присоединения к кластеру
$1 