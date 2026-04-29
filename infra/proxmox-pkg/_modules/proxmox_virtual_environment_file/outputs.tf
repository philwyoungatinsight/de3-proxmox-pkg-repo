output "file_id" {
  description = "Proxmox file ID of the uploaded file, e.g. 'local:snippets/cloud-init-guest-agent.cfg'."
  value       = proxmox_virtual_environment_file.this.id
}

output "file_name" {
  description = "Filename of the uploaded file as stored on the datastore"
  value       = proxmox_virtual_environment_file.this.file_name
}

output "node_name" {
  description = "Proxmox node the file was uploaded to"
  value       = proxmox_virtual_environment_file.this.node_name
}

output "datastore_id" {
  description = "Proxmox datastore the file was stored in"
  value       = proxmox_virtual_environment_file.this.datastore_id
}
