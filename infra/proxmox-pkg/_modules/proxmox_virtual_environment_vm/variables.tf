# ── Required ──────────────────────────────────────────────────────────────────

variable "node_name" {
  description = "Proxmox VE cluster node to create the VM on"
  type        = string
}

variable "vm_name" {
  description = "VM name as shown in the Proxmox UI"
  type        = string
}

# ── Identity / placement ──────────────────────────────────────────────────────

variable "vm_id" {
  description = "Proxmox VM ID (100–999999999). Null = auto-assign next free ID."
  type        = number
  default     = null
}

variable "pool_id" {
  description = "Proxmox resource pool to assign the VM to. Null = no pool."
  type        = string
  default     = null
}

variable "description" {
  description = "Free-text VM description shown in the Proxmox UI. Null = omit."
  type        = string
  default     = null
}

variable "tags" {
  description = "List of Proxmox tags to apply to the VM. Null = none."
  type        = list(string)
  default     = null
}

variable "additional_tags" {
  description = "Extra tags merged into the tags list. Useful for per-unit additions without overriding the base tags set by the terragrunt unit."
  type        = list(string)
  default     = []
}

variable "protection" {
  description = "Protect the VM from accidental deletion or modification. Null = Proxmox default (false)."
  type        = bool
  default     = null
}

variable "started" {
  description = "Whether the VM should be running after apply."
  type        = bool
  default     = true
}

variable "on_boot" {
  description = "Start the VM automatically when the Proxmox host boots."
  type        = bool
  default     = false
}

variable "stop_on_destroy" {
  description = "Force-stop the VM before destroying it. Null = Proxmox default (false)."
  type        = bool
  default     = null
}

# ── Firmware / machine ────────────────────────────────────────────────────────

variable "bios" {
  description = "'seabios' (legacy BIOS) or 'ovmf' (UEFI). Defaults to seabios."
  type        = string
  default     = "seabios"
  validation {
    condition     = contains(["seabios", "ovmf"], var.bios)
    error_message = "bios must be 'seabios' or 'ovmf'."
  }
}

variable "machine_type" {
  description = "QEMU machine type, e.g. 'q35' or 'pc'. Null = Proxmox default."
  type        = string
  default     = null
}

variable "scsi_hardware" {
  description = "SCSI controller model, e.g. 'virtio-scsi-pci', 'virtio-scsi-single', 'lsi'. Null = Proxmox default."
  type        = string
  default     = null
}

variable "kvm_arguments" {
  description = "Additional KVM/QEMU command-line arguments passed verbatim. Use with care. Null = none."
  type        = string
  default     = null
}

variable "boot_order" {
  description = "Ordered list of disk interface names to try at boot, e.g. ['virtio0', 'ide2']. Null = Proxmox default."
  type        = list(string)
  default     = null
}

# ── OS type hint ──────────────────────────────────────────────────────────────

variable "os_type" {
  description = "Guest OS type hint for Proxmox display optimizations, e.g. 'l26' (Linux 5.x+), 'l24', 'win10', 'win11', 'other'. Null = omit."
  type        = string
  default     = null
}

# ── CPU ───────────────────────────────────────────────────────────────────────

variable "cpu_cores" {
  description = "Number of CPU cores per socket."
  type        = number
  default     = 2
}

variable "cpu_sockets" {
  description = "Number of CPU sockets."
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "QEMU CPU model, e.g. 'host', 'kvm64', 'x86-64-v2-AES'. Null = Proxmox default (kvm64)."
  type        = string
  default     = null
}

variable "cpu_architecture" {
  description = "CPU architecture: 'x86_64' or 'aarch64'. Null = Proxmox default (x86_64)."
  type        = string
  default     = null
}

variable "cpu_flags" {
  description = "List of CPU feature flags to enable/disable, e.g. ['+aes', '-pcid']. Null = Proxmox default."
  type        = list(string)
  default     = null
}

variable "cpu_numa" {
  description = "Enable NUMA topology. Null = Proxmox default (false)."
  type        = bool
  default     = null
}

variable "cpu_limit" {
  description = "CPU usage cap (0–128, where 128 = full 1 physical core). Null = no limit."
  type        = number
  default     = null
}

variable "cpu_units" {
  description = "CPU scheduler weight (2–262144). Null = Proxmox default (1024)."
  type        = number
  default     = null
}

variable "cpu_hotplugged" {
  description = "Number of additional hotplugged vCPU cores. Null = none."
  type        = number
  default     = null
}

variable "cpu_affinity" {
  description = "CPU affinity as a string, e.g. '0-3' or '0,2'. Null = no affinity pinning."
  type        = string
  default     = null
}

# ── Memory ────────────────────────────────────────────────────────────────────

variable "memory_mb" {
  description = "RAM dedicated to the VM in MiB. Defaults to 8192 (8 GiB)."
  type        = number
  default     = 8192
}

variable "memory_balloon" {
  description = "Minimum RAM for the balloon device in MiB (enables dynamic memory). Null = no balloon (fixed RAM)."
  type        = number
  default     = null
}

variable "memory_hugepages" {
  description = "Hugepages size: '1024' (1 GiB pages), '2' (2 MiB pages), or 'any'. Null = disabled."
  type        = string
  default     = null
}

variable "memory_keep_hugepages" {
  description = "Keep hugepages allocated after VM shutdown. Null = Proxmox default (false)."
  type        = bool
  default     = null
}

variable "memory_shared" {
  description = "Shared RAM visible to other VMs via ivshmem in MiB. Null = none."
  type        = number
  default     = null
}

# ── ISO / CDROM ───────────────────────────────────────────────────────────────

variable "iso_file_id" {
  description = "Proxmox file ID of the ISO to mount, e.g. 'local:iso/ubuntu-22.04.iso'. Null = no CDROM."
  type        = string
  default     = null
}

variable "cdrom_interface" {
  description = "CDROM interface slot. Used when iso_file_id is set."
  type        = string
  default     = "ide2"
}

# ── Disk ──────────────────────────────────────────────────────────────────────

variable "disk_datastore" {
  description = "Proxmox datastore for the VM's primary disk, e.g. 'local-lvm'. Null = no disk created by this module."
  type        = string
  default     = null
}

variable "disk_size" {
  description = "Primary disk size in GiB."
  type        = number
  default     = 32
}

variable "disk_interface" {
  description = "Primary disk interface slot, e.g. 'virtio0', 'scsi0'."
  type        = string
  default     = "virtio0"
}

variable "disk_file_id" {
  description = "Proxmox file ID for an existing disk image to attach. Null = create a new disk."
  type        = string
  default     = null
}

variable "disk_import_from" {
  description = "Proxmox file ID to import as the primary disk (e.g. a cloud image). Null = no import."
  type        = string
  default     = null
  validation {
    condition     = var.disk_import_from == null || var.disk_file_id == null
    error_message = "disk_import_from and disk_file_id are mutually exclusive."
  }
}

variable "clone_vm_name" {
  description = "Name of a Proxmox template to clone. Resolved to a VM ID at plan time via proxmox_virtual_environment_vms data source."
  type        = string
  default     = null
}

variable "clone_node_name" {
  description = "Node name where the source template resides. Null = same node as the new VM."
  type        = string
  default     = null
}

variable "clone_datastore" {
  description = "Datastore for the cloned disk. Null = use disk_datastore."
  type        = string
  default     = null
}

variable "clone_full" {
  description = "Perform a full independent clone (true) or a linked clone (false)."
  type        = bool
  default     = true
}

variable "disk_format" {
  description = "Disk image format: 'raw', 'qcow2', 'vmdk'. Null = datastore default."
  type        = string
  default     = null
}

variable "disk_iothread" {
  description = "Enable IO thread for the disk (recommended with virtio-scsi-single). Null = Proxmox default (false)."
  type        = bool
  default     = null
}

variable "disk_discard" {
  description = "Discard/TRIM support: 'on' or 'ignore'. Null = Proxmox default."
  type        = string
  default     = null
}

variable "disk_cache" {
  description = "Disk cache mode: 'none', 'writeback', 'writethrough', 'directsync', 'unsafe'. Null = Proxmox default."
  type        = string
  default     = null
}

variable "disk_ssd" {
  description = "Emulate SSD for the disk. Null = Proxmox default (false)."
  type        = bool
  default     = null
}

variable "disk_backup" {
  description = "Include this disk in Proxmox backups. Null = Proxmox default (true)."
  type        = bool
  default     = null
}

# ── Network ───────────────────────────────────────────────────────────────────

variable "network_bridge" {
  description = "Linux bridge to attach the NIC to, e.g. 'vmbr0'. Null = no NIC created."
  type        = string
  default     = null
}

variable "network_model" {
  description = "NIC model: 'virtio', 'e1000', 'rtl8139'. Null = Proxmox default (virtio)."
  type        = string
  default     = null
}

variable "network_vlan_id" {
  description = "VLAN tag for the NIC (1–4094). Null = untagged."
  type        = number
  default     = null
}

variable "network_firewall" {
  description = "Enable the Proxmox firewall for this NIC. Null = Proxmox default (false)."
  type        = bool
  default     = null
}

variable "network_mac_address" {
  description = "Override MAC address (uppercase, colon-separated). Null = auto-generated."
  type        = string
  default     = null
}

variable "network_mtu" {
  description = "NIC MTU override. Null = inherit from bridge."
  type        = number
  default     = null
}

variable "network_queues" {
  description = "Number of queues for the NIC (multi-queue). Null = Proxmox default."
  type        = number
  default     = null
}

variable "network_rate_limit" {
  description = "NIC bandwidth rate limit in MiB/s. Null = unlimited."
  type        = number
  default     = null
}

# ── Second network interface (net1) ───────────────────────────────────────────
# Optional second NIC. Only created when network_bridge_2 is non-null.
# Used, for example, to give the MaaS server a NIC on the provisioning VLAN
# so it can serve DHCP/PXE there while its primary NIC stays on cloud_public.

variable "network_bridge_2" {
  description = "Linux bridge for the second NIC. Null = no second NIC created."
  type        = string
  default     = null
}

variable "network_vlan_id_2" {
  description = "VLAN tag for the second NIC (1–4094). Null = untagged."
  type        = number
  default     = null
}

# ── Cloud-Init ────────────────────────────────────────────────────────────────

variable "cloud_init_datastore" {
  description = "Datastore for the cloud-init drive, e.g. 'local-lvm'. Null = no cloud-init."
  type        = string
  default     = null
}

variable "cloud_init_user" {
  description = "Cloud-init default user name. Null = distro default."
  type        = string
  default     = null
}

variable "cloud_init_password" {
  description = "Cloud-init default user password (sensitive). Null = no password set."
  type        = string
  sensitive   = true
  default     = null
}

variable "cloud_init_ssh_keys" {
  description = "List of SSH public keys to inject via cloud-init. Null = none."
  type        = list(string)
  default     = null
}

variable "cloud_init_ip_address" {
  description = "Static IPv4 address in CIDR notation, e.g. '192.168.1.10/24'. Set to 'dhcp' for DHCP. Null = no ip_config block (cloud-init decides)."
  type        = string
  default     = null
}

variable "cloud_init_gateway" {
  description = "Default IPv4 gateway. Used when cloud_init_ip_address is set."
  type        = string
  default     = null
}

variable "cloud_init_dns_servers" {
  description = "List of DNS server IPs to configure via cloud-init. Null = inherit."
  type        = list(string)
  default     = null
}

variable "cloud_init_dns_domain" {
  description = "DNS search domain to configure via cloud-init. Null = inherit."
  type        = string
  default     = null
}

variable "cloud_init_user_data_file_id" {
  description = "Proxmox file ID of a custom cloud-init user-data file. Null = omit."
  type        = string
  default     = null
}

variable "cloud_init_meta_data_file_id" {
  description = "Proxmox file ID of a custom cloud-init meta-data file. Null = omit."
  type        = string
  default     = null
}

variable "cloud_init_vendor_data_file_id" {
  description = "Proxmox file ID of a custom cloud-init vendor-data file. Null = omit."
  type        = string
  default     = null
}

variable "cloud_init_network_data_file_id" {
  description = "Proxmox file ID of a custom cloud-init network-config file. Null = omit."
  type        = string
  default     = null
}

# ── QEMU Guest Agent ──────────────────────────────────────────────────────────

variable "agent_enabled" {
  description = "Enable the QEMU guest agent (requires qemu-guest-agent inside the VM). Null = omit agent block entirely."
  type        = bool
  default     = null
}

variable "agent_trim" {
  description = "Enable FSTRIM via the guest agent. Used when agent_enabled is set."
  type        = bool
  default     = null
}

variable "agent_type" {
  description = "Agent transport type: 'virtio' or 'isa'. Null = Proxmox default."
  type        = string
  default     = null
}

variable "agent_timeout" {
  description = "Timeout for agent operations, e.g. '15m'. Null = Proxmox default."
  type        = string
  default     = null
}

# ── VGA / Display ─────────────────────────────────────────────────────────────

variable "vga_type" {
  description = "VGA controller type: 'std', 'vmware', 'qxl', 'virtio', 'serial0', 'none'. Null = omit vga block."
  type        = string
  default     = null
}

variable "vga_memory" {
  description = "VGA memory in MiB. Used when vga_type is set. Null = Proxmox default."
  type        = number
  default     = null
}

# ── Serial device ─────────────────────────────────────────────────────────────

variable "serial_device" {
  description = "Serial device to add: 'socket' (most common) or a host device path. Null = no serial device."
  type        = string
  default     = null
}

# ── Timeouts ──────────────────────────────────────────────────────────────────

variable "timeout_create" {
  description = "Timeout in seconds for VM creation. Null = provider default (~5 min)."
  type        = number
  default     = null
}

variable "timeout_start_vm" {
  description = "Timeout in seconds for VM start. Null = provider default."
  type        = number
  default     = null
}

variable "timeout_stop_vm" {
  description = "Timeout in seconds for VM stop. Null = provider default."
  type        = number
  default     = null
}

variable "timeout_reboot" {
  description = "Timeout in seconds for VM reboot. Null = provider default."
  type        = number
  default     = null
}

variable "timeout_shutdown_vm" {
  description = "Timeout in seconds for VM graceful shutdown. Null = provider default."
  type        = number
  default     = null
}
