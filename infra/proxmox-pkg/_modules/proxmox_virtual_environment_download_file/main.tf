# Downloads a file (ISO, LXC template, or importable disk image) from a
# URL directly onto a Proxmox VE node's datastore via the Proxmox API.

resource "proxmox_virtual_environment_download_file" "this" {
  node_name    = var.node_name
  datastore_id = var.datastore_id
  content_type = var.content_type
  url          = var.url

  file_name               = var.file_name
  checksum                = var.checksum
  checksum_algorithm      = var.checksum_algorithm
  decompression_algorithm = var.decompression_algorithm
  overwrite               = var.overwrite
  overwrite_unmanaged     = var.overwrite_unmanaged
  upload_timeout          = var.upload_timeout
  verify                  = var.verify
}
