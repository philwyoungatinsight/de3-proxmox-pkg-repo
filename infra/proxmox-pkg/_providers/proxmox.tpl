# Proxmox VE: native provider for VM and container provisioning.
# endpoint: https://<host>:8006  (full URL, port 8006 required)
# Auth (set exactly one in the secrets file under providers.proxmox):
#   api_token: "user@realm!token_id=uuid"  (preferred)
#   username + password: "root@pam" / "password"
# insecure: true skips TLS verification – typical for homelab self-signed certs.
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    proxmox = { source = "bpg/proxmox", version = "~> 0.68" }
    null    = { source = "hashicorp/null" }
  }
}
provider "proxmox" {
  endpoint = "${ENDPOINT}"
  insecure = ${INSECURE}
  %{if TOKEN_ID != ""}api_token = "${TOKEN_ID}=${TOKEN_SECRET}"%{~ endif}
  %{if TOKEN_ID == "" && API_TOKEN != ""}api_token = "${API_TOKEN}"%{~ endif}
  %{if USERNAME != ""}username  = "${USERNAME}"%{endif}
  %{if PASSWORD != ""}password  = "${PASSWORD}"%{endif}
  %{if SSH_USERNAME != ""}
  ssh {
    agent    = ${SSH_AGENT}
    username = "${SSH_USERNAME}"
  }
  %{endif}
}
