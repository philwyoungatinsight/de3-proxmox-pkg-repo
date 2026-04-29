output "vm_id" {
  description = "Proxmox VM ID assigned to this virtual machine"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = proxmox_virtual_environment_vm.this.name
}

output "node_name" {
  description = "Proxmox node the VM was created on"
  value       = proxmox_virtual_environment_vm.this.node_name
}

output "ipv4_addresses" {
  description = "IPv4 addresses reported by the QEMU guest agent (populated after VM starts and agent is running)"
  value       = proxmox_virtual_environment_vm.this.ipv4_addresses
}

output "mac_addresses" {
  description = "MAC addresses of the VM's network interfaces"
  value       = proxmox_virtual_environment_vm.this.mac_addresses
}

output "network_mac_address" {
  description = "The MAC address configured for the primary network interface"
  value       = var.network_mac_address
}
