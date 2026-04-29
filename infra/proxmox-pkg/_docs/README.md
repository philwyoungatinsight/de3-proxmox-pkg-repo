# MaaS-Provisioned Proxmox Host Setup

## Goal

A physical machine managed by MaaS can become a fully automated Proxmox VE server.
Running `make clean-all && make` from scratch (after one-time physical hardware setup)
must produce a working Proxmox node without any manual intervention.

ms01-01 is the current example: a Minisforum MS-01 that MaaS deploys with Debian 13 (trixie),
after which the automation installs and configures Proxmox VE 9 on it.

---

## Background

- **MaaS Machine**: A physical or virtual machine provisioned via PXE, managed by MaaS.
- **Proxmox Server / Node**: A server running the Proxmox VE hypervisor.
- **Proxmox Cluster**: A group of Proxmox nodes managed as a single entity.
- A MaaS-provisioned Proxmox server is a machine that transitions:
  **PXE boot → Debian 13 trixie (via MaaS) → Proxmox VE 9 (via Ansible)**

---

## Prerequisites (one-time physical setup per machine)

- BIOS: disable Secure Boot; enable PXE in boot order.
- MEBx (Intel AMT): activate AMT, set admin password, enable network access.
  → See [machine-onboarding.md](../../maas-pkg/_docs/machine-onboarding.md) for full instructions.
- Cable the machine's PXE NIC to the provisioning VLAN trunk port on the switch.

Everything after this is automated.

---

## How to Add a New MaaS-Provisioned Proxmox Host

### Step 1 — Add MaaS machine config

Edit the deployment package config YAML (e.g. `infra/pwy-home-lab-pkg/_config/pwy-home-lab-pkg.yaml`)
under the `providers.maas.config_params` section:

```yaml
"<your-pkg>/_stack/maas/<deployment>/machines/<machine-name>":
  additional_tags: ["role_mgmt_group_<group>", "role_proxmox_server"]
  cloud_init_user: debian          # MaaS Debian 13 default user
  power_type: smart_plug           # Use smart_plug if available; amt otherwise
  poll_timeout_secs: 300
  pxe_mac_address: "<PXE NIC MAC>"
  power_address: "<AMT IP>"        # Static AMT management IP (or smart-plug URL)
  deploy_distro: trixie            # Debian 13 — required for Proxmox VE 9 (bookworm → PVE 8, trixie → PVE 9)
```

Key requirements:
- `deploy_distro: trixie` — Debian 13 (trixie) installs Proxmox VE 9. Debian 12 (bookworm) would give PVE 8. Do NOT use Ubuntu.
- `cloud_init_user: debian` — MaaS sets this as the default SSH user for Debian deployments.
- `role_proxmox_server` tag — triggers the `hypervisor.proxmox.install` wave.
- `power_type: smart_plug` — preferred over `amt` when a smart plug is available (AMT is unreliable on MS-01 hardware).

### Step 2 — Add Proxmox node config

In the same YAML file, under `providers.proxmox.config_params`, add a `pve-nodes/` entry:

```yaml
"<your-pkg>/_stack/proxmox/<deployment>/pve-nodes/<machine-name>":
  ansible_host: "<VLAN-12-IP>"     # MaaS DHCP-assigned IP on provisioning VLAN
  ansible_user: debian             # MaaS Debian 13 default user; becomes root after Proxmox install
  ansible_ssh_common_args: >-
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
    -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ubuntu@<maas-rack-provisioning-ip>"
  node_name: "<machine-name>"      # Proxmox node name (hostname)
  bridge_technology: vlan-aware    # Configures vmbr0 as VLAN-aware bridge
  vlan_bridge: vmbr0
  datastore_iso: local
  api_token_id: tg-token
```

Key points:
- `ansible_host` is the **VLAN 12 (provisioning) IP** assigned by MaaS DHCP. This is
  not a management VLAN IP — the machine is accessed through the provisioning network.
- `ansible_ssh_common_args` uses `ProxyCommand` (not `-J`) to jump through the MaaS
  rack-1 provisioning NIC (`_maas_server_ip` + provisioning VLAN) because the controller
  has no direct route to VLAN 12 (provisioning, 10.0.12.0/24).
- The `pve-nodes/` path prefix is required for `generate_ansible_inventory.py` to
  include this node in the `pve_hosts` Ansible group.

### Step 3 — Commit and run

No other files need editing. The automation handles the rest:

```bash
source $(git rev-parse --show-toplevel)/set_env.sh
./run --build
```

Or from the Makefile:

```bash
make
```

---

## Automation Flow (wave order)

The following waves are relevant for a MaaS-provisioned Proxmox host:

| Wave | What happens |
|------|-------------|
| `maas.servers.all` | MaaS server VM created and fully configured (DHCP, images, preseeds). |
| `maas.machine.config.power` | Registers AMT/smart-plug power drivers in MaaS for all physical machines; acts as the aggregating dependency gate before Proxmox install. |
| `hypervisor.proxmox.install` | Pre-check verifies SSH reachability. Proxmox VE 9 installed on all `role_proxmox_server` hosts. Up to 6 retries with 120 s delay. Polls until `pveproxy`, `pvedaemon`, `pvestatd` are active and port 8006 is reachable. |
| `hypervisor.proxmox.configure` | Pre-check verifies Proxmox API is reachable on all pve nodes (including the newly installed node). Configures ALL nodes: storage content types, Terraform API token, VLAN-aware bridge, cloud_public subinterface, MaaS SSH key sync. API token written automatically to SOPS. |
| `hypervisor.proxmox.storage` | Uploads ISOs and cloud-init snippets to the new node so it can run VMs. |

### Why the wave separation matters

- `hypervisor.proxmox.install` runs **only** on newly MaaS-deployed Debian 13 hosts — it skips nodes that already have Proxmox installed.
- `hypervisor.proxmox.configure` runs on **all** pve nodes (old and new) and is idempotent — established nodes see no changes if they are already correctly configured.

---

## Networking and SSH Access

MaaS-provisioned hosts land on **VLAN 12 (provisioning, 10.0.12.0/24)** after OS deploy.
The controller has no direct route to VLAN 12 — all SSH goes via ProxyCommand through the
MaaS rack-1 provisioning NIC (`ubuntu@<rack-provisioning-ip>`, where the IP comes from
`_maas_server_ip` + VLAN 12 interface), configured in `ansible_ssh_common_args`.

The assigned DHCP IP is generally stable per MAC but may change on redeploy. If it
changes, update `ansible_host` in the YAML. For strict stability, add a static DHCP
reservation in MaaS (web UI → Subnet → Reserved ranges).

See [network planning](../unifi-pkg/README.md) for full VLAN definitions
and switch port assignments.

---

## What configure-proxmox Does

After Proxmox VE is installed, `configure-proxmox` (`playbook.configure-pve.yaml`) runs
the following tasks in order. Each task is idempotent and skipped automatically if the
host is not yet running the Proxmox API:

1. **Storage** (`configure-local-storage.yaml`): Adds `snippets` and `import` content
   types to the `local` storage pool, and ensures `/var/lib/vz/snippets/` exists.
   Required for cloud-init vendor-data snippets and template imports.

2. **API token** (`configure-api-token.yaml`): Creates `root@pam!tg-token` with
   `privsep=0` (required for Terragrunt to manage VMs without 403 errors). If the
   token already exists, verifies `privsep=0` and corrects it if wrong.
   The token secret is **written automatically** to `proxmox-pkg/_config/proxmox-pkg_secrets.sops.yaml`
   under `proxmox-pkg_secrets.providers.proxmox.config_params["<unit-path>"].token`.

3. **Bridge networking** (`configure-vlan-aware-bridge.yaml`, `configure-linux-bridge.yaml`,
   `configure-ovs-bridge.yaml`): Configures `vmbr0` based on the node's `bridge_technology`
   config key (`vlan-aware`, `linux-bridge`, or `ovs`). The `verify-bridge-config.yaml` task
   asserts the resulting bridge matches expected config.

4. **Cloud public VLAN** (`configure-cloud-public-vlan.yaml`): Adds a VLAN sub-interface
   on `vmbr0` for the cloud_public VLAN so the Proxmox host itself can reach cloud services.

5. **MaaS SSH key sync** (`sync-maas-ssh-key.yaml`): Copies the MaaS region controller's
   root SSH public key into the Proxmox node's `authorized_keys`, so MaaS can SSH in after
   future deploys without manual key rotation.

A separate `playbook.configure-pve-networking.yaml` handles pure networking changes
(bridge type, VLAN subinterface) in isolation — used by the networking-only wave variant.

---

## Current Example: ms01-01

ms01-01 is a Minisforum MS-01 physical server configured as follows:

| Parameter | Value |
|-----------|-------|
| MaaS machine path | `pwy-home-lab-pkg/_stack/maas/pwy-homelab/machines/ms01-01` |
| Proxmox node path | `pwy-home-lab-pkg/_stack/proxmox/pwy-homelab/pve-nodes/ms01-01` |
| OS deployed by MaaS | Debian 13 (trixie) |
| Proxmox version | Proxmox VE 9 |
| VLAN | 12 (provisioning, 10.0.12.0/24) |
| ansible_host | `10.0.12.237` (MaaS DHCP) |
| Jump host | `ubuntu@10.0.12.2` (MaaS rack-1 VLAN 12 interface) |
| AMT IP | `10.0.11.10` (management VLAN 11) |
| PXE MAC | `38:05:25:31:2f:a3` (port 3, i226-V) |
| Proxmox node_name | `ms01-01` |

---

## Appendix A — Proxmox VE 9 Installation Steps

The `install-proxmox` Ansible playbook (`infra/proxmox-pkg/_tg_scripts/proxmox/install/`) performs:

1. Assert OS is Debian 13 (trixie). Fail if not.
2. Set `/etc/hosts` so `hostname -f` resolves to the machine's primary LAN IP (required by PVE).
3. Download Proxmox GPG key from `enterprise.proxmox.com`.
4. Add `pve-no-subscription` apt repository; disable the enterprise subscription repo.
5. `apt full-upgrade`.
6. Install `proxmox-default-kernel`; reboot if kernel changed.
7. Install `proxmox-ve postfix open-iscsi chrony`.
8. Remove Debian default kernel (`linux-image-amd64`, `linux-image-6.1*`).
9. `update-grub`; remove `os-prober`.
10. Enable and start `pveproxy`, `pvedaemon`, `pvestatd`.

After install, `install-proxmox --test` polls every 30 seconds (up to `_PROXMOX_VE_WAIT_TIMEOUT`,
default 600 s) until all services pass verification and port 8006 is reachable.

---

## Appendix B — Troubleshooting

**install-proxmox fails: host unreachable**

MaaS may not have finished deploying Debian 13 (trixie). Check:
- `infra/maas-pkg/_wave_scripts/common/check-maas-machines/run` — is the machine enlisted?
- MaaS web UI → Machine → check commission/deploy status.
- Is the DHCP IP the same as `ansible_host` in the YAML? Run
  `$_GENERATE_INVENTORY --build` (or `make -C infra/_framework-pkg/_framework/_generate-inventory build`) and inspect the output.

**configure-proxmox fails for ms01-01 at `hypervisor.proxmox.configure`**

The pre-check (`proxmox-configure-precheck`) runs before apply and verifies the API is
reachable on all nodes. If this fails, Proxmox may have installed but SSH or the API
is not yet ready. If this fails:
- Verify `pveproxy` and `sshd` are running: the `hypervisor.proxmox.install` test should have caught this.
- Check `ansible_host` IP — run `nmap -p 22 <ansible_host>` from the controller.
- Check ProxyCommand: `ssh -o ProxyCommand="ssh -W %h:%p ubuntu@10.0.12.2" debian@<ansible_host>`.

**API token not found in SOPS**

`configure-api-token.yaml` writes the token via `sops --set` after creating it.
If the SOPS write fails (e.g. `sops` not in PATH), the token ID and secret are printed
to the Ansible output — copy them and write to the secrets file manually with `sops`.

**IP changes after redeploy**

If MaaS assigns a different IP on redeploy, update `ansible_host` in the
`pwy-home-lab-pkg/_stack/proxmox/pwy-homelab/pve-nodes/<machine-name>` block
in `infra/pwy-home-lab-pkg/_config/pwy-home-lab-pkg.yaml`.
