#!/bin/bash
set -e

apt-get update -y
apt-get install -y curl

SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/shared/node-token"

echo "[INFO] Waiting for token from server (max 120s)..."
for i in $(seq 1 60); do
  if [ -f "$TOKEN_FILE" ]; then
    break
  fi
  sleep 2
done

if [ ! -f "$TOKEN_FILE" ]; then
  echo "[ERROR] Timeout waiting for token file after 120s."
  exit 1
fi

# Read token efficiently into variable
TOKEN=$(cat $TOKEN_FILE)
echo "[INFO] Token received from server."

echo "[INSTALL] Installing K3s worker..."
curl -sfL https://get.k3s.io | \
  K3S_URL="https://$SERVER_IP:6443" \
  K3S_TOKEN="$TOKEN" \
  INSTALL_K3S_EXEC="--flannel-iface=enp0s8" \
  sh -

echo "[SUCCESS] Worker successfully joined cluster."
