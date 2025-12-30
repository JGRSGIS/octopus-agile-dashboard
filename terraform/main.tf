# Octopus Agile Dashboard - Oracle Cloud Infrastructure Deployment
# OpenTofu/Terraform configuration for deploying the full application stack

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}

# Configure the Oracle Cloud Infrastructure provider
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Data sources for availability domains and images
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.ubuntu_version
  shape                    = var.compute_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Generate SSH key pair if not provided
resource "tls_private_key" "ssh" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Generate random password for database
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# Networking module - VCN, subnets, security lists
module "network" {
  source = "./modules/network"

  compartment_ocid     = var.compartment_ocid
  vcn_cidr_block       = var.vcn_cidr_block
  vcn_display_name     = "${var.project_name}-vcn"
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  project_name         = var.project_name
  allowed_ssh_cidrs    = var.allowed_ssh_cidrs
  enable_ipv6          = var.enable_ipv6

  tags = local.common_tags
}

# Compute module - VM instance
module "compute" {
  source = "./modules/compute"

  compartment_ocid    = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  subnet_id           = module.network.public_subnet_id
  nsg_ids             = [module.network.app_nsg_id]

  instance_name       = "${var.project_name}-instance"
  shape               = var.compute_shape
  ocpus               = var.compute_ocpus
  memory_gb           = var.compute_memory_gb
  boot_volume_size_gb = var.boot_volume_size_gb
  image_id            = data.oci_core_images.ubuntu.images[0].id

  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.ssh[0].public_key_openssh

  cloud_init_script = templatefile("${path.module}/scripts/cloud-init.yaml", {
    project_name          = var.project_name
    db_host               = module.database.db_private_ip
    db_port               = 5432
    db_name               = var.db_name
    db_user               = var.db_user
    db_password           = random_password.db_password.result
    redis_enabled         = var.enable_redis
    octopus_api_key       = var.octopus_api_key
    octopus_mpan          = var.octopus_mpan
    octopus_serial_number = var.octopus_serial_number
    octopus_region        = var.octopus_region
    github_repo           = var.github_repo
    app_domain            = var.app_domain
    enable_ssl            = var.enable_ssl
    admin_email           = var.admin_email
  })

  tags = local.common_tags

  depends_on = [module.network, module.database]
}

# Database module - PostgreSQL on compute or Autonomous DB
module "database" {
  source = "./modules/database"

  compartment_ocid    = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  subnet_id           = module.network.private_subnet_id
  nsg_ids             = [module.network.db_nsg_id]

  db_instance_name    = "${var.project_name}-db"
  shape               = var.db_compute_shape
  ocpus               = var.db_compute_ocpus
  memory_gb           = var.db_compute_memory_gb
  boot_volume_size_gb = var.db_boot_volume_size_gb
  image_id            = data.oci_core_images.ubuntu.images[0].id

  db_name     = var.db_name
  db_user     = var.db_user
  db_password = random_password.db_password.result

  ssh_public_key = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.ssh[0].public_key_openssh

  tags = local.common_tags

  depends_on = [module.network]
}

# Secrets module - OCI Vault for sensitive data
module "secrets" {
  source = "./modules/secrets"
  count  = var.enable_vault ? 1 : 0

  compartment_ocid = var.compartment_ocid
  vault_name       = "${var.project_name}-vault"
  key_name         = "${var.project_name}-master-key"

  secrets = {
    db_password       = random_password.db_password.result
    octopus_api_key   = var.octopus_api_key
  }

  tags = local.common_tags

  depends_on = [module.database]
}

# Monitoring module - Alarms and notifications
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.enable_monitoring ? 1 : 0

  compartment_ocid   = var.compartment_ocid
  project_name       = var.project_name
  instance_id        = module.compute.instance_id
  db_instance_id     = module.database.instance_id
  notification_email = var.admin_email

  cpu_alarm_threshold    = var.cpu_alarm_threshold
  memory_alarm_threshold = var.memory_alarm_threshold
  disk_alarm_threshold   = var.disk_alarm_threshold

  tags = local.common_tags

  depends_on = [module.compute, module.database]
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}
