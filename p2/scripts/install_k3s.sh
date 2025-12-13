#!/bin/bash
set -e

apt update -y
apt install -y curl

echo "[INSTALL] Installing K3s server..."
curl -sfL https://get.k3s.io | sh -

echo "[WAIT] Waiting for K3s API server to be ready..."
until sudo /usr/local/bin/kubectl get nodes >/dev/null 2>&1; do
  sleep 2
done

echo "[DEPLOY] Applying application manifests..."
sudo /usr/local/bin/kubectl apply -f /vagrant/confs/app1.yaml
sudo /usr/local/bin/kubectl apply -f /vagrant/confs/app2.yaml
sudo /usr/local/bin/kubectl apply -f /vagrant/confs/app3.yaml
sudo /usr/local/bin/kubectl apply -f /vagrant/confs/ingress.yaml

echo "[DONE] K3s installed and applications deployed."
