# Upload a file (e.g., cloud-init snippet) to a Proxmox VE datastore.
#
# Two modes:
#   source_file_path     - upload a local file via SSH/SFTP (requires SSH access)
#   source_file_content  - upload inline content via the Proxmox API (no SSH needed)

locals {
  rendered_file_name = coalesce(var.file_name, "uploaded-snippet.cfg")
}

resource "proxmox_virtual_environment_file" "this" {
  node_name    = var.node_name
  datastore_id = var.datastore_id
  content_type = var.content_type

  # Inline content: uploaded via the Proxmox REST API – no SSH required.
  dynamic "source_raw" {
    for_each = var.source_file_path == null ? [1] : []
    content {
      data      = coalesce(var.source_file_content, "")
      file_name = local.rendered_file_name
    }
  }

  # File path: uploaded via SSH/SFTP. Only used when source_file_path is set.
  dynamic "source_file" {
    for_each = var.source_file_path != null ? [1] : []
    content {
      path = var.source_file_path
    }
  }
}
