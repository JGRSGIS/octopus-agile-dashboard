# Secrets Module Outputs

output "vault_id" {
  description = "OCID of the vault"
  value       = oci_kms_vault.main.id
}

output "vault_crypto_endpoint" {
  description = "Crypto endpoint of the vault"
  value       = oci_kms_vault.main.crypto_endpoint
}

output "vault_management_endpoint" {
  description = "Management endpoint of the vault"
  value       = oci_kms_vault.main.management_endpoint
}

output "master_key_id" {
  description = "OCID of the master encryption key"
  value       = oci_kms_key.master.id
}

output "secret_ids" {
  description = "Map of secret names to OCIDs"
  value       = { for k, v in oci_vault_secret.secrets : k => v.id }
}
