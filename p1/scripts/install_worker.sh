#!/bin/bash
set -e

apt update -y
apt install -y curl

SERVER_IP="192.168.56.110"
TOKEN_FILE="/vagrant/shared/node-token"

echo "[INFO] Waiting for token from server..."
WAIT_COUNT=0
while [ ! -f "$TOKEN_FILE" ]; do
  sleep 2
  WAIT_COUNT=$((WAIT_COUNT + 1))
  if [ $WAIT_COUNT -gt 60 ]; then
    echo "[ERROR] Timeout waiting for token file. Server may have failed."
    exit 1
  fi
done

TOKEN=$(cat $TOKEN_FILE)
echo "[INFO] Token received from server."

echo "[INSTALL] Installing K3s worker..."
curl -sfL https://get.k3s.io | \
  K3S_URL="https://$SERVER_IP:6443" \
  K3S_TOKEN="$TOKEN" \
  INSTALL_K3S_EXEC="--flannel-iface=enp0s8" \
  sh -

echo "[SUCCESS] Worker successfully joined cluster."
