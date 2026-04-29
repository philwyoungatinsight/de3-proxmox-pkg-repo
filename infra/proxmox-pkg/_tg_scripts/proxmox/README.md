# tg-scripts/proxmox-pkg/proxmox

Proxmox VE installation, configuration, and readiness scripts.

| Script | Wave | Purpose |
|--------|------|---------|
| [`install/`](install/README.md) | `hypervisor.proxmox.install` | Install Proxmox VE on MaaS-deployed Debian 13 (trixie) hosts: mask systemd-networkd, install proxmox-ve via apt, reboot, wait for API on port 8006. |
| [`configure/`](configure/README.md) | `hypervisor.proxmox.configure` | Configure ALL Proxmox nodes (pve-1, pve-2, ms01-01, ms01-02, ms01-03): VLAN-aware bridge, cloud_public VLAN subinterface, local storage content types, Terraform API token (`root@pam!tg-token`), MaaS root SSH key sync. Runs via two null units: `configure-proxmox` (main config) and `configure-proxmox-post-install` (post-install steps for newly installed nodes). |
| `wait-for-api/` | (internal) | Poll Proxmox API port 8006 until reachable — used as a Terraform local-exec dependency check. |
