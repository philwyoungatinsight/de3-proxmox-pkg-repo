# ── Required ──────────────────────────────────────────────────────────────────

variable "node_name" {
  description = "Proxmox VE cluster node that will perform the upload"
  type        = string
}

variable "datastore_id" {
  description = "Proxmox datastore to store the uploaded file, e.g. 'local'"
  type        = string
}

variable "source_file_path" {
  description = "Local file path to upload to the datastore"
  type        = string
  default     = null
}

# Optional: render content to a local file inside the module.
variable "source_file_content" {
  description = "Inline file content to upload when source_file_path is null"
  type        = string
  default     = null
}

variable "file_name" {
  description = "Filename to use when rendering source_file_content"
  type        = string
  default     = null
}

# ── File identity ─────────────────────────────────────────────────────────────

variable "content_type" {
  description = "Proxmox content type: 'snippets', 'iso', 'vztmpl', or 'import'"
  type        = string
  default     = "snippets"
}
