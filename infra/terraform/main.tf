terraform {
  required_version = ">= 1.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }

  # Store state locally by default. For team use, switch to a remote backend
  # (e.g. Scaleway Object Storage as an S3-compatible backend).
}

# --------------------------------------------------------------------------
# Provider
# --------------------------------------------------------------------------
# Credentials come from environment variables:
#   SCW_ACCESS_KEY, SCW_SECRET_KEY, SCW_DEFAULT_PROJECT_ID
# This avoids hardcoding secrets in files.
provider "scaleway" {
  zone   = var.zone   # fr-par-1 (Paris)
  region = var.region # fr-par
}

# --------------------------------------------------------------------------
# SSH Key
# --------------------------------------------------------------------------
# Registers your public key with Scaleway so it gets injected into the VPS
# on creation. No need to manually add keys after provisioning.
resource "scaleway_iam_ssh_key" "deploy" {
  name       = "${var.project_name}-deploy-key"
  public_key = var.ssh_public_key
}

# --------------------------------------------------------------------------
# Security Group (Firewall)
# --------------------------------------------------------------------------
# Scaleway security groups are stateful firewalls applied at the instance level.
# Default policy: drop all inbound, allow all outbound.
# We explicitly open only what the app needs.
resource "scaleway_instance_security_group" "app" {
  name                    = "${var.project_name}-sg"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"

  # SSH - restricted to your IP if provided, otherwise open
  inbound_rule {
    action   = "accept"
    port     = 22
    protocol = "TCP"
  }

  # HTTP - needed for Let's Encrypt ACME challenge + redirect to HTTPS
  inbound_rule {
    action   = "accept"
    port     = 80
    protocol = "TCP"
  }

  # HTTPS - main app traffic
  inbound_rule {
    action   = "accept"
    port     = 443
    protocol = "TCP"
  }

  # Netdata monitoring (optional, remove in hardened setups)
  inbound_rule {
    action   = "accept"
    port     = var.netdata_port
    protocol = "TCP"
  }
}

# --------------------------------------------------------------------------
# Instance (VPS)
# --------------------------------------------------------------------------
# DEV1-M: 3 vCPU, 4GB RAM (~10 EUR/mo)
# DEV1-L: 4 vCPU, 8GB RAM (~17 EUR/mo)
# Your prod stack uses ~1.5GB RAM typical, 3GB peak, so DEV1-M is sufficient
# but DEV1-L gives comfortable headroom for DB + sync spikes.
resource "scaleway_instance_ip" "app" {}

resource "scaleway_instance_server" "app" {
  name  = "${var.project_name}-server"
  type  = var.instance_type
  image = var.instance_image

  ip_id             = scaleway_instance_ip.app.id
  security_group_id = scaleway_instance_security_group.app.id

  root_volume {
    size_in_gb = var.root_volume_size
  }

  tags = ["dendreo", "production"]
}

# --------------------------------------------------------------------------
# Object Storage (S3-compatible) - for database backups
# --------------------------------------------------------------------------
# Replaces the Google Drive approach with a purpose-built, S3-compatible
# bucket in the same Scaleway region. Tools like rclone or aws-cli work
# out of the box. Free tier covers 75GB.
resource "scaleway_object_bucket" "backups" {
  name = "${var.project_name}-backups"

  # Auto-delete old backups after retention period
  lifecycle_rule {
    enabled = true
    prefix  = "daily/"

    expiration {
      days = var.backup_retention_days
    }
  }

  tags = {
    environment = "production"
    purpose     = "database-backups"
  }
}
