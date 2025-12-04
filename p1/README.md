# p1 — K3s test cluster (2 VMs: controller + agent)

This document describes the `p1` environment and provisioning for a two-node K3s cluster using Vagrant + VirtualBox. It also summarizes fixes and steps to run, verify, and troubleshoot the cluster.

---

## Overview

This `p1` folder provides a minimal two-VM Kubernetes (K3s) cluster:

- Controller (server): `hnaciriS` — static IP `192.168.56.110`
- Worker (agent): `hnaciriSW` — static IP `192.168.56.111`

Files:
- `Vagrantfile` — defines the two VirtualBox VMs and provisioning steps
- `scripts/setup_ssh.sh` — SSH setup for `vagrant` user
- `scripts/install_server.sh` — installs K3s server and writes the node token to a shared folder
- `scripts/install_worker.sh` — waits for the token and installs K3s agent using that token

---

## Main Design & Configuration

### Vagrantfile
- Each machine is defined with a hostname and fixed IP on a host-only network.
- A private shared folder (`/vagrant`) is mounted for sharing the node token between VMs.
- Provider settings: VirtualBox with 2 CPUs and 2048 MB memory (updated from 1/1024 to improve stability).

### Provisioning scripts
- `setup_ssh.sh` — Generate an SSH key for `vagrant` user and append the public key to `authorized_keys`.
- `install_server.sh` — Installs K3s server using the official installer and sets `INSTALL_K3S_EXEC="--flannel-iface=enp0s8"` so the flannel network binds to the private NIC. It waits for `node-token` to be created and copies it to `/vagrant/shared/node-token`.
- `install_worker.sh` — Waits for `/vagrant/shared/node-token` (with a timeout), reads it, and installs the K3s agent using `K3S_URL` and `K3S_TOKEN`. It also sets `INSTALL_K3S_EXEC="--flannel-iface=enp0s8"` to bind the agent network to the private NIC.

---

## Fixes and Changes (Implemented)

These updates were applied to make the setup resilient and functional:

1. Added `config.vm.synced_folder ".", "/vagrant"` to `Vagrantfile` so `/vagrant` is available in VMs — required to share the token.
2. Increased resources in `Vagrantfile` to `vb.memory = 2048` and `vb.cpus = 2` to avoid K3s instability due to low resources.
3. Updated `install_server.sh` to:
   - Use `INSTALL_K3S_EXEC="--flannel-iface=enp0s8"` to bind to the private NIC (the VM’s private NIC is `enp0s8`, not `eth1`).
   - Wait for `node-token` to exist and ensure safe copy + permissions: `chmod 644`.
4. Updated `install_worker.sh` to:
   - Wait for `/vagrant/shared/node-token` with a `WAIT_COUNT` and exit if a timeout occurs to avoid indefinite provisioning.
   - Use `INSTALL_K3S_EXEC="--flannel-iface=enp0s8"` to bind the agent to the same interface.
5. Recreated the VMs to apply the configuration and resolved stale vagrant lock/provision artifacts.

---

## How to Run

Prerequisites:
- Host: VirtualBox and Vagrant installed (matching Vagrant and VirtualBox versions are recommended).
- Enough host RAM/disk and Internet access (K3s binaries will be downloaded).

Commands (run from `p1` directory):

Start both VMs (from the `p1` project directory):

```bash
vagrant up
```

This will create both VMs, boot them, and run provisioning in order (server first, then worker). If you want to ensure a sequence, start the server first:

```bash
vagrant up hnaciriS
vagrant up hnaciriSW
```

Stop or destroy VMs:

```bash
vagrant halt
vagrant destroy -f
```

---

## Verify the Cluster

Quick checks to confirm both nodes joined and pods are running:

```bash
vagrant ssh hnaciriS -c 'sudo kubectl get nodes'
vagrant ssh hnaciriS -c 'sudo kubectl get pods -A'
```

If you prefer to use `kubectl` from the host, copy the kubeconfig and change the server address:

```bash
cp confs/k3s.yaml ~/kube/p1-k3s.yaml
sed -i 's/127.0.0.1/192.168.56.110/g' ~/kube/p1-k3s.yaml
export KUBECONFIG=~/kube/p1-k3s.yaml
kubectl get nodes
```

---

 

## Quick Cleanup (if needed)

```bash
# Stop and destroy VMs (run from the `p1` project directory)
vagrant halt
vagrant destroy -f

# Remove vagrant cache (optional)
vagrant box list
vagrant box remove --all <box-name>
rm -rf ~/.vagrant.d/boxes

# Remove VM folder leftovers
rm -rf ~/.vagrant.d
```

---

## Checklist: Successful Run (what you should see)

- `vagrant up` finishes without errors
- `sudo systemctl status k3s` shows `active (running)` on the server
- `vagrant ssh hnaciriS -c "sudo kubectl get nodes"` shows both nodes with `Ready` status
- `vagrant ssh hnaciriS -c "sudo kubectl get pods -A"` shows core components running (coredns, local-path-provisioner or helm-related if installed)

---

If you'd like, I can also:
- Add dynamic NIC detection to avoid hardcoding `enp0s8`,
- Make `setup_ssh.sh` idempotent, or
- Convert the two sets (Alpine vs Ubuntu) into a single canonical `p1` folder. 

Tell me which option you want next or if you want this README saved anywhere else.
