#!/bin/bash
set -e

apt update -y
apt install -y curl

echo "[INSTALL] Installing K3s server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-iface=enp0s8" sh -

echo "[INFO] Waiting for K3s server to be ready..."
sleep 5

# Wait for the node token to be available
TOKEN_PATH="/var/lib/rancher/k3s/server/node-token"
while [ ! -f "$TOKEN_PATH" ]; do
  echo "[WAIT] Token not yet available, waiting..."
  sleep 2
done

echo "[INFO] K3s server installed."
echo "[INFO] Token location: $TOKEN_PATH"

# Save token in a shared folder accessible by worker
mkdir -p /vagrant/shared
cp $TOKEN_PATH /vagrant/shared/node-token

echo "[SUCCESS] Server setup complete. Token saved to /vagrant/shared/node-token"
