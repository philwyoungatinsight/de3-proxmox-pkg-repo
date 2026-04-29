# ── Required ──────────────────────────────────────────────────────────────────

variable "node_name" {
  description = "Proxmox VE cluster node that will perform the download"
  type        = string
}

variable "datastore_id" {
  description = "Proxmox datastore to store the downloaded file, e.g. 'local'"
  type        = string
}

variable "url" {
  description = "HTTP/HTTPS URL of the file to download"
  type        = string
}

# ── File identity ─────────────────────────────────────────────────────────────

variable "content_type" {
  description = "Proxmox content type: 'iso', 'vztmpl' (LXC template), or 'import' (disk image)"
  type        = string
  default     = "iso"
  validation {
    condition     = contains(["iso", "vztmpl", "import"], var.content_type)
    error_message = "content_type must be 'iso', 'vztmpl', or 'import'."
  }
}

variable "file_name" {
  description = "Override the filename stored on the datastore. Null = derived from the URL."
  type        = string
  default     = null
}

# ── Integrity verification ────────────────────────────────────────────────────

variable "checksum" {
  description = "Expected checksum of the downloaded file. Null = no checksum verification."
  type        = string
  default     = null
}

variable "checksum_algorithm" {
  description = "Hash algorithm for checksum verification: 'md5', 'sha1', 'sha224', 'sha256', 'sha384', 'sha512'. Required when checksum is set."
  type        = string
  default     = null
  validation {
    condition = (
      var.checksum_algorithm == null ||
      contains(["md5", "sha1", "sha224", "sha256", "sha384", "sha512"], var.checksum_algorithm)
    )
    error_message = "checksum_algorithm must be one of: md5, sha1, sha224, sha256, sha384, sha512."
  }
}

# ── Download behaviour ────────────────────────────────────────────────────────

variable "decompression_algorithm" {
  description = "Decompress the file after download: 'gz', 'lz4', 'bz2', 'zstd', 'xz'. Null = no decompression."
  type        = string
  default     = null
  validation {
    condition = (
      var.decompression_algorithm == null ||
      contains(["gz", "lz4", "bz2", "zstd", "xz"], var.decompression_algorithm)
    )
    error_message = "decompression_algorithm must be one of: gz, lz4, bz2, zstd, xz."
  }
}

variable "overwrite" {
  description = "Re-download and overwrite the file if it already exists on the datastore. Null = Proxmox default (true)."
  type        = bool
  default     = null
}

variable "overwrite_unmanaged" {
  description = "Overwrite a file on the datastore that was not created by Terraform. Null = Proxmox default (false)."
  type        = bool
  default     = null
}

variable "upload_timeout" {
  description = "Timeout in seconds for the download/upload operation. Null = Proxmox default (600 s)."
  type        = number
  default     = null
}

variable "verify" {
  description = "Verify the downloaded file. Null = Proxmox default (true)."
  type        = bool
  default     = null
}
