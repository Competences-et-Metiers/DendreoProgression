# --------------------------------------------------------------------------
# Scaleway region/zone
# --------------------------------------------------------------------------
variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par" # Paris - closest to your French users
}

variable "zone" {
  description = "Scaleway availability zone"
  type        = string
  default     = "fr-par-1"
}

# --------------------------------------------------------------------------
# Project naming
# --------------------------------------------------------------------------
variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "dendreo"
}

# --------------------------------------------------------------------------
# Instance configuration
# --------------------------------------------------------------------------
variable "instance_type" {
  description = "Scaleway instance type (DEV1-M = 3vCPU/4GB, DEV1-L = 4vCPU/8GB)"
  type        = string
  default     = "DEV1-L" # 4 vCPU, 8GB RAM - comfortable for your full stack
}

variable "instance_image" {
  description = "OS image for the instance"
  type        = string
  default     = "ubuntu_jammy" # Ubuntu 22.04 LTS - stable, well-supported
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 80 # Enough for Docker images, DB data, and local backups
}

# --------------------------------------------------------------------------
# SSH
# --------------------------------------------------------------------------
variable "ssh_public_key" {
  description = "SSH public key for the deploy user (content, not path)"
  type        = string
}

# --------------------------------------------------------------------------
# Networking
# --------------------------------------------------------------------------
variable "netdata_port" {
  description = "Port for Netdata monitoring dashboard"
  type        = number
  default     = 19999
}

# --------------------------------------------------------------------------
# Backups
# --------------------------------------------------------------------------
variable "backup_retention_days" {
  description = "Number of days to keep daily backups in object storage"
  type        = number
  default     = 30
}
