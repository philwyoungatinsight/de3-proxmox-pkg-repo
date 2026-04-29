# Proxmox VE virtual machine with cloud-init support.
#
# Always-rendered blocks: cpu, memory  (have required defaults)
# Conditionally-rendered blocks (omitted when the controlling var is null):
#   operating_system, cdrom, disk, network_device, initialization, agent, vga, serial_device
# Optional scalar attributes are passed as-is; null = provider default.

# ── Template name lookup ───────────────────────────────────────────────────────
# When clone_vm_name is set, resolve it to a numeric VM ID at plan time.

data "proxmox_virtual_environment_vms" "clone_template" {
  count     = var.clone_vm_name != null ? 1 : 0
  node_name = var.clone_node_name

  filter {
    name   = "name"
    values = [var.clone_vm_name]
  }
  filter {
    name   = "template"
    values = ["true"]
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  node_name = var.node_name
  name      = var.vm_name
  vm_id     = var.vm_id
  pool_id   = var.pool_id

  bios          = var.bios
  machine       = var.machine_type
  scsi_hardware = var.scsi_hardware
  kvm_arguments = var.kvm_arguments
  boot_order    = var.boot_order

  started         = var.started
  on_boot         = var.on_boot
  protection      = var.protection
  stop_on_destroy = var.stop_on_destroy
  description     = var.description
  tags            = concat(coalesce(var.tags, []), var.additional_tags)

  timeout_create      = var.timeout_create
  timeout_start_vm    = var.timeout_start_vm
  timeout_stop_vm     = var.timeout_stop_vm
  timeout_reboot      = var.timeout_reboot
  timeout_shutdown_vm = var.timeout_shutdown_vm

  # ── CPU ────────────────────────────────────────────────────────────────────

  cpu {
    cores        = var.cpu_cores
    sockets      = var.cpu_sockets
    type         = var.cpu_type
    architecture = var.cpu_architecture
    flags        = var.cpu_flags
    numa         = var.cpu_numa
    limit        = var.cpu_limit
    units        = var.cpu_units
    hotplugged   = var.cpu_hotplugged
    affinity     = var.cpu_affinity
  }

  # ── Memory ─────────────────────────────────────────────────────────────────

  memory {
    dedicated       = var.memory_mb
    floating        = var.memory_balloon
    hugepages       = var.memory_hugepages
    keep_hugepages  = var.memory_keep_hugepages
    shared          = var.memory_shared
  }

  # ── OS type hint ───────────────────────────────────────────────────────────

  dynamic "operating_system" {
    for_each = var.os_type != null ? [1] : []
    content {
      type = var.os_type
    }
  }

  # ── CDROM / ISO ────────────────────────────────────────────────────────────

  dynamic "cdrom" {
    for_each = var.iso_file_id != null ? [1] : []
    content {
      file_id   = var.iso_file_id
      interface = var.cdrom_interface
    }
  }

  # ── Clone from template ────────────────────────────────────────────────────
  # Omitted when clone_vm_name is not set.
  # VM ID is resolved at plan time via the proxmox_virtual_environment_vms data source.

  dynamic "clone" {
    for_each = var.clone_vm_name != null ? [1] : []
    content {
      vm_id        = data.proxmox_virtual_environment_vms.clone_template[0].vms[0].vm_id
      node_name    = var.clone_node_name
      datastore_id = coalesce(var.clone_datastore, var.disk_datastore)
      full         = var.clone_full
    }
  }

  # ── Primary disk ───────────────────────────────────────────────────────────

  dynamic "disk" {
    for_each = var.disk_datastore != null ? [1] : []
    content {
      datastore_id = var.disk_datastore
      interface    = var.disk_interface
      file_id      = var.disk_file_id
      import_from  = var.disk_import_from
      size         = var.disk_size
      file_format  = var.disk_format
      iothread     = var.disk_iothread
      discard      = var.disk_discard
      cache        = var.disk_cache
      ssd          = var.disk_ssd
      backup       = var.disk_backup
    }
  }

  # ── Network interface ──────────────────────────────────────────────────────

  dynamic "network_device" {
    for_each = var.network_bridge != null ? [1] : []
    content {
      bridge      = var.network_bridge
      model       = var.network_model
      vlan_id     = var.network_vlan_id
      firewall    = var.network_firewall
      mac_address = var.network_mac_address
      mtu         = var.network_mtu
      queues      = var.network_queues
      rate_limit  = var.network_rate_limit
    }
  }

  # Optional second NIC (net1). Only created when network_bridge_2 is set.
  dynamic "network_device" {
    for_each = var.network_bridge_2 != null ? [1] : []
    content {
      bridge  = var.network_bridge_2
      vlan_id = var.network_vlan_id_2
    }
  }

  # ── Cloud-Init ─────────────────────────────────────────────────────────────
  # Omitted entirely when cloud_init_datastore is null.

  dynamic "initialization" {
    for_each = var.cloud_init_datastore != null ? [1] : []
    content {
      datastore_id             = var.cloud_init_datastore
      user_data_file_id        = var.cloud_init_user_data_file_id
      meta_data_file_id        = var.cloud_init_meta_data_file_id
      vendor_data_file_id      = var.cloud_init_vendor_data_file_id
      network_data_file_id     = var.cloud_init_network_data_file_id

      # User account – omitted when no user, password, or SSH keys are supplied.
      dynamic "user_account" {
        for_each = (
          var.cloud_init_user     != null ||
          var.cloud_init_password != null ||
          var.cloud_init_ssh_keys != null
        ) ? [1] : []
        content {
          username = var.cloud_init_user
          password = var.cloud_init_password
          keys     = var.cloud_init_ssh_keys != null ? var.cloud_init_ssh_keys : []
        }
      }

      # Static or DHCP IP – omitted when neither address nor gateway is specified,
      # leaving cloud-init free to use its own network configuration.
      dynamic "ip_config" {
        for_each = (
          var.cloud_init_ip_address != null ||
          var.cloud_init_gateway    != null
        ) ? [1] : []
        content {
          ipv4 {
            address = coalesce(var.cloud_init_ip_address, "dhcp")
            gateway = var.cloud_init_gateway
          }
        }
      }

      # DNS – omitted when neither servers nor domain is specified.
      dynamic "dns" {
        for_each = (
          var.cloud_init_dns_servers != null ||
          var.cloud_init_dns_domain  != null
        ) ? [1] : []
        content {
          servers = var.cloud_init_dns_servers
          domain  = var.cloud_init_dns_domain
        }
      }
    }
  }

  # ── QEMU Guest Agent ───────────────────────────────────────────────────────

  dynamic "agent" {
    for_each = var.agent_enabled != null ? [1] : []
    content {
      enabled = var.agent_enabled
      trim    = var.agent_trim
      type    = var.agent_type
      timeout = var.agent_timeout
    }
  }

  # ── VGA / Display ──────────────────────────────────────────────────────────

  dynamic "vga" {
    for_each = var.vga_type != null ? [1] : []
    content {
      type   = var.vga_type
      memory = var.vga_memory
    }
  }

  # ── Serial device ──────────────────────────────────────────────────────────

  dynamic "serial_device" {
    for_each = var.serial_device != null ? [1] : []
    content {
      device = var.serial_device
    }
  }
}
