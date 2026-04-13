# --------------------------------------------------------------------------
# Outputs
# --------------------------------------------------------------------------
# These values are needed by Ansible and GitHub Actions after provisioning.

output "server_ip" {
  description = "Public IP address of the VPS"
  value       = scaleway_instance_ip.app.address
}

output "server_id" {
  description = "Scaleway instance ID"
  value       = scaleway_instance_server.app.id
}

output "backup_bucket_name" {
  description = "Object storage bucket name for DB backups"
  value       = scaleway_object_bucket.backups.name
}

output "backup_bucket_endpoint" {
  description = "S3-compatible endpoint for the backup bucket"
  value       = scaleway_object_bucket.backups.endpoint
}

output "ansible_inventory_entry" {
  description = "Copy this into your Ansible inventory"
  value       = "dendreo_server ansible_host=${scaleway_instance_ip.app.address} ansible_user=root"
}
