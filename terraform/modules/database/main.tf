# Database Module - PostgreSQL on Compute Instance

# ============================================================================
# Database Compute Instance
# ============================================================================

resource "oci_core_instance" "db" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = var.db_instance_name
  shape               = var.shape

  # Flex shape configuration
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

  # Network configuration - Private subnet, no public IP
  create_vnic_details {
    subnet_id        = var.subnet_id
    display_name     = "${var.db_instance_name}-vnic"
    assign_public_ip = false
    hostname_label   = replace(var.db_instance_name, "-", "")
    nsg_ids          = var.nsg_ids
  }

  # Metadata including SSH key and cloud-init
  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.db_cloud_init)
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

  lifecycle {
    prevent_destroy = false  # Set to true in production

    ignore_changes = [
      metadata["user_data"],
      defined_tags
    ]
  }

  freeform_tags = var.tags
}

# ============================================================================
# Block Volume for PostgreSQL Data
# ============================================================================

resource "oci_core_volume" "db_data" {
  compartment_id      = var.compartment_ocid
  availability_domain = var.availability_domain
  display_name        = "${var.db_instance_name}-data"
  size_in_gbs         = var.data_volume_size_gb

  vpus_per_gb = 20  # Higher performance for database

  freeform_tags = var.tags
}

resource "oci_core_volume_attachment" "db_data" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.db.id
  volume_id       = oci_core_volume.db_data.id
  display_name    = "${var.db_instance_name}-data-attachment"

  is_pv_encryption_in_transit_enabled = true
  is_read_only                        = false
}

# ============================================================================
# Boot Volume Backup Policy
# ============================================================================

resource "oci_core_volume_backup_policy_assignment" "db_boot" {
  count = var.enable_backup ? 1 : 0

  asset_id  = oci_core_instance.db.boot_volume_id
  policy_id = data.oci_core_volume_backup_policies.gold[0].volume_backup_policies[0].id
}

resource "oci_core_volume_backup_policy_assignment" "db_data" {
  count = var.enable_backup ? 1 : 0

  asset_id  = oci_core_volume.db_data.id
  policy_id = data.oci_core_volume_backup_policies.gold[0].volume_backup_policies[0].id
}

data "oci_core_volume_backup_policies" "gold" {
  count = var.enable_backup ? 1 : 0

  filter {
    name   = "display_name"
    values = ["gold"]
  }
}

# ============================================================================
# Cloud-Init Script for PostgreSQL Setup
# ============================================================================

locals {
  db_cloud_init = <<-EOF
#cloud-config
package_update: true
package_upgrade: true

packages:
  - postgresql-14
  - postgresql-contrib-14
  - python3-pip

write_files:
  - path: /tmp/setup_postgres.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      set -e

      # Wait for PostgreSQL to start
      sleep 10

      # Configure PostgreSQL to listen on all interfaces
      sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/14/main/postgresql.conf

      # Configure pg_hba.conf for remote connections
      echo "host    all             all             10.0.0.0/16             scram-sha-256" | sudo tee -a /etc/postgresql/14/main/pg_hba.conf

      # Performance tuning for small instance
      cat >> /etc/postgresql/14/main/postgresql.conf << 'PGCONF'

      # Memory settings (adjust based on instance size)
      shared_buffers = 256MB
      effective_cache_size = 512MB
      work_mem = 16MB
      maintenance_work_mem = 128MB

      # WAL settings
      wal_buffers = 16MB
      checkpoint_completion_target = 0.9

      # Query planning
      random_page_cost = 1.1
      effective_io_concurrency = 200

      # Logging
      log_min_duration_statement = 1000
      log_checkpoints = on
      log_connections = on
      log_disconnections = on
      log_lock_waits = on

      PGCONF

      # Restart PostgreSQL
      sudo systemctl restart postgresql

      # Create database and user
      sudo -u postgres psql << SQL
      CREATE USER ${var.db_user} WITH PASSWORD '${var.db_password}' CREATEDB;
      CREATE DATABASE ${var.db_name} OWNER ${var.db_user};
      GRANT ALL PRIVILEGES ON DATABASE ${var.db_name} TO ${var.db_user};
      \c ${var.db_name}
      GRANT ALL ON SCHEMA public TO ${var.db_user};
      SQL

      echo "PostgreSQL setup complete!"

  - path: /etc/systemd/system/postgres-setup.service
    content: |
      [Unit]
      Description=PostgreSQL Initial Setup
      After=postgresql.service

      [Service]
      Type=oneshot
      ExecStart=/tmp/setup_postgres.sh
      RemainAfterExit=yes

      [Install]
      WantedBy=multi-user.target

runcmd:
  # Wait for apt locks to clear
  - while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 1; done

  # Run the setup script
  - /tmp/setup_postgres.sh

  # Enable PostgreSQL to start on boot
  - systemctl enable postgresql

  # Setup firewall
  - ufw allow 5432/tcp
  - ufw --force enable

final_message: "PostgreSQL database server is ready. Took $UPTIME seconds."
EOF
}
