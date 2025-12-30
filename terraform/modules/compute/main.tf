# Compute Module - Application Server Instance

# ============================================================================
# Compute Instance
# ============================================================================

resource "oci_core_instance" "app" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = var.instance_name
  shape               = var.shape

  # Flex shape configuration (for A1.Flex, E4.Flex, Standard3.Flex)
  dynamic "shape_config" {
    for_each = can(regex("Flex", var.shape)) ? [1] : []
    content {
      ocpus         = var.ocpus
      memory_in_gbs = var.memory_gb
    }
  }

  # Source details (boot image)
  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  # Network configuration
  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.instance_name}-vnic"
    assign_public_ip = true
    hostname_label   = replace(var.instance_name, "-", "")
    nsg_ids          = var.nsg_ids
  }

  # Metadata including SSH key and cloud-init
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(var.cloud_init_script)
  }

  # Agent configuration
  agent_config {
    is_monitoring_disabled = false
    is_management_disabled = false

    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }

    plugins_config {
      desired_state = "ENABLED"
      name          = "OS Management Service Agent"
    }

    plugins_config {
      desired_state = "ENABLED"
      name          = "Custom Logs Monitoring"
    }

    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Run Command"
    }
  }

  # Launch options
  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
    is_pv_encryption_in_transit_enabled = true
  }

  # Availability configuration
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }

  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = false  # Set to true in production

    ignore_changes = [
      metadata["user_data"],  # Ignore cloud-init changes after creation
      defined_tags
    ]
  }

  freeform_tags = var.tags
}

# ============================================================================
# Block Volume for Application Data (Optional)
# ============================================================================

resource "oci_core_volume" "app_data" {
  count = var.create_data_volume ? 1 : 0

  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "${var.instance_name}-data"
  size_in_gbs         = var.data_volume_size_gb

  vpus_per_gb = 10  # Balanced performance

  freeform_tags = var.tags
}

resource "oci_core_volume_attachment" "app_data" {
  count = var.create_data_volume ? 1 : 0

  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.app.id
  volume_id       = oci_core_volume.app_data[0].id
  display_name    = "${var.instance_name}-data-attachment"

  is_pv_encryption_in_transit_enabled = true
  is_read_only                        = false
}

# ============================================================================
# Boot Volume Backup Policy (for data protection)
# ============================================================================

resource "oci_core_volume_backup_policy_assignment" "app_boot" {
  count = var.enable_boot_volume_backup ? 1 : 0

  asset_id  = oci_core_instance.app.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.silver[0].volume_backup_policies[0].id
}

data "oci_core_volume_backup_policies" "silver" {
  count = var.enable_boot_volume_backup ? 1 : 0

  filter {
    name   = "display_name"
    values = ["silver"]
  }
}
