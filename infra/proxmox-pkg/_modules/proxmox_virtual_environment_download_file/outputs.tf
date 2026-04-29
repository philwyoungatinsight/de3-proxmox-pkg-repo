output "file_id" {
  description = "Proxmox file ID of the downloaded file, e.g. 'local:iso/ubuntu-24.04.iso' or 'local:import/ubuntu-24.04-cloudimg.qcow2'."
  value       = proxmox_virtual_environment_download_file.this.id
}

output "file_name" {
  description = "Filename of the downloaded file as stored on the datastore"
  value       = proxmox_virtual_environment_download_file.this.file_name
}

output "node_name" {
  description = "Proxmox node the file was downloaded to"
  value       = proxmox_virtual_environment_download_file.this.node_name
}

output "datastore_id" {
  description = "Proxmox datastore the file was stored in"
  value       = proxmox_virtual_environment_download_file.this.datastore_id
}
