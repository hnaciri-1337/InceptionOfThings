#!/bin/bash
set -e

echo "[1/6] Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates gnupg lsb-release vim

echo "[2/6] Installing Docker..."
sudo curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

echo "[3/6] Installing kubectl..."
curl -Ls https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl | sudo install -o root -g root -m 0755 /dev/stdin /usr/local/bin/kubectl

echo "[4/6] Installing k3d..."
sudo curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "[5/6] Creating k3d cluster..."
sudo k3d cluster create iot-cluster --servers 1 --agents 1 --port "8888:8888@loadbalancer"

echo "[6/6] Installing ArgoCD..."
sudo kubectl create namespace argocd
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sudo kubectl create namespace dev

git config --global user.name "hnaciri-1337"

echo "DONE ✅"
echo "Run: kubectl get pods -n argocd"

