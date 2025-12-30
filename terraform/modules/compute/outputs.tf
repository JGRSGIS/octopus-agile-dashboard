# Compute Module Outputs

output "instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.app.id
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.app.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.app.private_ip
}

output "boot_volume_id" {
  description = "OCID of the boot volume"
  value       = oci_core_instance.app.boot_volume_id
}

output "instance_state" {
  description = "Current state of the instance"
  value       = oci_core_instance.app.state
}

output "time_created" {
  description = "Time the instance was created"
  value       = oci_core_instance.app.time_created
}
