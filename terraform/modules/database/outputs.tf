# Database Module Outputs

output "instance_id" {
  description = "OCID of the database instance"
  value       = oci_core_instance.db.id
}

output "db_private_ip" {
  description = "Private IP address of the database server"
  value       = oci_core_instance.db.private_ip
}

output "db_hostname" {
  description = "Hostname of the database server"
  value       = oci_core_instance.db.hostname_label
}

output "boot_volume_id" {
  description = "OCID of the boot volume"
  value       = oci_core_instance.db.boot_volume_id
}

output "data_volume_id" {
  description = "OCID of the data volume"
  value       = oci_core_volume.db_data.id
}

output "connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql+asyncpg://${var.db_user}:****@${oci_core_instance.db.private_ip}:5432/${var.db_name}"
}
