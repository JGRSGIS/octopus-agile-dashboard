# Secrets Module - OCI Vault for Secrets Management

# ============================================================================
# OCI Vault
# ============================================================================

resource "oci_kms_vault" "main" {
  compartment_id = var.compartment_ocid
  display_name   = var.vault_name
  vault_type     = "DEFAULT"

  freeform_tags = var.tags
}

# ============================================================================
# Master Encryption Key
# ============================================================================

resource "oci_kms_key" "master" {
  compartment_id = var.compartment_ocid
  display_name   = var.key_name
  key_shape {
    algorithm = "AES"
    length    = 32  # 256-bit key
  }
  management_endpoint = oci_kms_vault.main.management_endpoint
  protection_mode     = "SOFTWARE"  # Use HSM for production

  freeform_tags = var.tags
}

# ============================================================================
# Secrets
# ============================================================================

resource "oci_vault_secret" "secrets" {
  for_each = var.secrets

  compartment_id = var.compartment_ocid
  vault_id       = oci_kms_vault.main.id
  key_id         = oci_kms_key.master.id
  secret_name    = "${var.vault_name}-${each.key}"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(each.value)
  }

  freeform_tags = var.tags

  lifecycle {
    ignore_changes = [
      secret_content  # Don't update secrets on subsequent applies
    ]
  }
}

# ============================================================================
# IAM Policy for Secrets Access (Optional - create separately if needed)
# ============================================================================

# Note: IAM policies should typically be managed at a higher level.
# This is provided as a reference for what's needed.

# Example policy statement for instance to read secrets:
# Allow dynamic-group <instance-dynamic-group> to read secret-family in compartment <compartment>
# Allow dynamic-group <instance-dynamic-group> to use keys in compartment <compartment>
