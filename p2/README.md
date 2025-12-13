# p2 — Single-node K3s demo (haithamS)

This document describes the `p2` environment. The `p2` folder creates a single K3s VM (`haithamS`) and deploys three nginx apps (app1, app2, app3) behind Traefik ingress.

---

## Overview

- Single VirtualBox VM: `haithamS` (static IP: `192.168.56.110`)
- K3s server (control-plane & worker) installed on the VM
- Demo apps: `app1`, `app2`, `app3` deployed in `default` namespace using `app1.yaml`, `app2.yaml`, `app3.yaml` in `confs/`
- `ingress.yaml` contains an Ingress resource with host-based routing for `app1.com`, `app2.com`, `app3.com` and a default backend to `app3`.
- Optional `index-html/` contains fancy index HTML files; the manifests may either contain inline `ConfigMap`s or the provisioning script can be updated to create `ConfigMap`s from these files.

---

## Files

- `Vagrantfile` — defines `haithamS`, pinned box, resources, and a synced `/vagrant` folder
- `scripts/install_k3s.sh` — installs K3s and applies manifests. (If you want config maps to be created from files in `index-html/`, see the section below.)
- `confs/app1.yaml`, `confs/app2.yaml`, `confs/app3.yaml` — each contain a `ConfigMap` with `index.html`, a Deployment, and a Service for the app
- `confs/ingress.yaml` — Ingress with host rules and default backend
- `confs/index-html/*/index.html` — optional HTML files (fancy demos). If you prefer editing HTML separately, you can have provisioning create ConfigMaps from these files instead of keeping inline ConfigMaps in YAML.

---

## How to run (quick start)

From `p2` directory on the host:

```bash
vagrant up
```

Once the VM is up you can check the K3s cluster status and resources:

```bash
# Check node and pods
vagrant ssh haithamS -c "sudo kubectl get nodes && sudo kubectl get pods -A"

# Check services and ingress
vagrant ssh haithamS -c "sudo kubectl get svc -A && sudo kubectl get ingress -A"
```

To access the apps locally, add an entry to your `/etc/hosts` file (as root):

```
192.168.56.110 app1.com app2.com app3.com
```

Then use a browser or curl to query each host:

```bash
curl -s http://app1.com
curl -s http://app2.com
curl -s http://app3.com
```

You should see the HTML for each app. Traefik is the default Ingress controller in K3s and should pick up the `Ingress` resource.

---

## ConfigMap approaches

You can serve the HTML either by embedding it in the `ConfigMap` inside `app{x}.yaml` or by creating the `ConfigMap` from the `index-html` files. Both approaches are supported;

- Inline ConfigMap (current default): `app{x}.yaml` includes `ConfigMap` with `index.html` inlined. After editing the HTML you must re-apply the manifest and restart pods (pods read ConfigMaps at startup):

  ```bash
  vagrant ssh haithamS -c "sudo kubectl apply -f /vagrant/confs/app1.yaml"
  vagrant ssh haithamS -c "sudo kubectl rollout restart deployment/app1"
  ```

- ConfigMap-from-file (recommended for live development): Update the provisioning script `scripts/install_k3s.sh` or run from the VM to create the `ConfigMap` from the `index-html` file:

  ```bash
  vagrant ssh haithamS -c "sudo kubectl create configmap app1-html --from-file=index.html=/vagrant/confs/index-html/app1/index.html --dry-run=client -o yaml | sudo kubectl apply -f -"
  vagrant ssh haithamS -c "sudo kubectl rollout restart deployment/app1"
  ```

  Repeat for `app2` and `app3`.

---

## Ingress rules & Default behavior

The `confs/ingress.yaml` contains host rules for `app1.com`, `app2.com`, `app3.com` and includes a fallback rule (catch-all/`defaultBackend`) to `app3`.

Behavior verified by tests:

- `http://app1.com` → serves `app1`
- `http://app2.com` → serves `app2`
- `http://app3.com` → serves `app3`
- `http://192.168.56.110` or unknown Host header → falls back to `app3` (default backend catch-all)

Note: some Ingress controllers (Traefik) may require adding a catch-all rule in the `Ingress` resource or an explicit `defaultBackend` in `ingress.yaml`.

---

## Troubleshooting tips

- `404` or `404 page not found`:
  - Confirm `kubectl get ingress` shows `apps-ingress` with host rules and an `ADDRESS` assigned.
  - Confirm pods/services are running: `kubectl get pods,svc`.
  - If `ConfigMap` was updated inline (in the YAML), reapply manifest and restart pods.

- `Traefik` not routing:
  - Confirm `kube-system` `traefik-*` pod is running: `kubectl -n kube-system get pods | grep traefik`.
  - Check Traefik logs: `kubectl logs -n kube-system <traefik-pod-name>`.

- `Ingress status pending` or no `ADDRESS` assigned:
  - K3s Traefik exposes a `LoadBalancer` service; VirtualBox isn't a public cloud so Traefik may show an `EXTERNAL-IP` that points to the internal NAT host IP (10.0.2.15) or  `192.168.56.110`, ensure your `/etc/hosts` maps to the VM IP when testing.

---

## Useful commands

```bash
# Watch pods in real time
vagrant ssh haithamS -c "sudo kubectl get pods -w"

# Tail logs for an app
vagrant ssh haithamS -c "sudo kubectl logs -l app=app2 -f"

# Describe ingress if routing is broken
vagrant ssh haithamS -c "sudo kubectl describe ingress apps-ingress"

# Recreate ConfigMap from files (if you prefer file-based workflow)
vagrant ssh haithamS -c "sudo kubectl create configmap app1-html --from-file=index.html=/vagrant/confs/index-html/app1/index.html --dry-run=client -o yaml | sudo kubectl apply -f -"

# Reapply manifests and restart deployments
vagrant ssh haithamS -c "sudo kubectl apply -f /vagrant/confs && sudo kubectl rollout restart deployment/app1 deployment/app2 deployment/app3"
```

---

## Notes & Extras

- `p2` is designed to be a single-node K3s demo that’s easy to boot and test with local hostnames. If you prefer a multi-node testbed, see `p1` which configures a controller + worker.
- If you want the provision script to automatically build ConfigMaps from `index-html/`, I can update `scripts/install_k3s.sh` to create configmaps using `kubectl create configmap --from-file` and then apply the rest of the manifests.

---

If you want me to: 
- Update the `install_k3s.sh` provisioning script to generate ConfigMaps automatically (and remove inline ConfigMaps from `app{x}.yaml`), or
- Switch `app{x}.yaml` to reference external `index-html` files (either as `ConfigMap` or mounting a host folder),

say which option you prefer and I’ll implement it.
