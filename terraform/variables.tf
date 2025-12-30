# Octopus Agile Dashboard - Terraform Variables
# Customize these values for your deployment

# ============================================================================
# OCI Authentication - Required
# ============================================================================

variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the OCI API signing key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key file"
  type        = string
}

variable "compartment_ocid" {
  description = "OCID of the compartment where resources will be created"
  type        = string
}

variable "region" {
  description = "OCI region (e.g., uk-london-1, eu-frankfurt-1)"
  type        = string
  default     = "uk-london-1"
}

# ============================================================================
# Project Settings
# ============================================================================

variable "project_name" {
  description = "Name of the project, used as prefix for resources"
  type        = string
  default     = "agile-dashboard"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# ============================================================================
# Networking
# ============================================================================

variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (app server)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (database)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH into instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production!
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the VCN"
  type        = bool
  default     = false
}

# ============================================================================
# Compute Instance (Application Server)
# ============================================================================

variable "compute_shape" {
  description = "Compute shape for the application server"
  type        = string
  default     = "VM.Standard.A1.Flex"  # ARM-based, free tier eligible

  validation {
    condition = contains([
      "VM.Standard.A1.Flex",      # ARM Ampere (free tier: 4 OCPUs, 24GB RAM total)
      "VM.Standard.E2.1.Micro",   # AMD (free tier: 1/8 OCPU, 1GB RAM)
      "VM.Standard.E4.Flex",      # AMD EPYC (paid)
      "VM.Standard3.Flex"         # Intel (paid)
    ], var.compute_shape)
    error_message = "Invalid compute shape. Use VM.Standard.A1.Flex for free tier ARM or VM.Standard.E2.1.Micro for free tier AMD."
  }
}

variable "compute_ocpus" {
  description = "Number of OCPUs for the application server (only for Flex shapes)"
  type        = number
  default     = 1

  validation {
    condition     = var.compute_ocpus >= 1 && var.compute_ocpus <= 4
    error_message = "OCPUs must be between 1 and 4 for free tier compliance."
  }
}

variable "compute_memory_gb" {
  description = "Memory in GB for the application server (only for Flex shapes)"
  type        = number
  default     = 6

  validation {
    condition     = var.compute_memory_gb >= 1 && var.compute_memory_gb <= 24
    error_message = "Memory must be between 1 and 24 GB for free tier compliance."
  }
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB (free tier allows 200GB total)"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_gb >= 47 && var.boot_volume_size_gb <= 200
    error_message = "Boot volume size must be between 47 and 200 GB."
  }
}

variable "ubuntu_version" {
  description = "Ubuntu version to use"
  type        = string
  default     = "22.04"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access (leave empty to generate)"
  type        = string
  default     = ""
}

# ============================================================================
# Database Instance
# ============================================================================

variable "db_compute_shape" {
  description = "Compute shape for the database server"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "db_compute_ocpus" {
  description = "Number of OCPUs for the database server"
  type        = number
  default     = 1
}

variable "db_compute_memory_gb" {
  description = "Memory in GB for the database server"
  type        = number
  default     = 6
}

variable "db_boot_volume_size_gb" {
  description = "Boot volume size for database in GB"
  type        = number
  default     = 50
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "octopus_agile"
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = "octopus"
}

# ============================================================================
# Application Configuration
# ============================================================================

variable "octopus_api_key" {
  description = "Octopus Energy API key (from octopus.energy/dashboard/developer)"
  type        = string
  sensitive   = true
}

variable "octopus_mpan" {
  description = "MPAN (Meter Point Administration Number) - 13 digits"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{13}$", var.octopus_mpan))
    error_message = "MPAN must be exactly 13 digits."
  }
}

variable "octopus_serial_number" {
  description = "Electricity meter serial number"
  type        = string
}

variable "octopus_region" {
  description = "DNO region code (A-P)"
  type        = string
  default     = "H"

  validation {
    condition     = can(regex("^[A-P]$", var.octopus_region))
    error_message = "Region must be a single letter from A to P."
  }
}

variable "github_repo" {
  description = "GitHub repository URL for the application"
  type        = string
  default     = "https://github.com/JGRSGIS/octopus-agile-dashboard.git"
}

variable "app_domain" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "enable_ssl" {
  description = "Enable SSL/TLS with Let's Encrypt"
  type        = bool
  default     = false
}

variable "admin_email" {
  description = "Admin email for SSL certificates and notifications"
  type        = string
  default     = ""
}

variable "enable_redis" {
  description = "Enable Redis caching"
  type        = bool
  default     = true
}

# ============================================================================
# Security & Secrets
# ============================================================================

variable "enable_vault" {
  description = "Enable OCI Vault for secrets management"
  type        = bool
  default     = false  # Set to true for production
}

# ============================================================================
# Monitoring & Alerts
# ============================================================================

variable "enable_monitoring" {
  description = "Enable OCI monitoring and alarms"
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "CPU usage percentage threshold for alarms"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory usage percentage threshold for alarms"
  type        = number
  default     = 85
}

variable "disk_alarm_threshold" {
  description = "Disk usage percentage threshold for alarms"
  type        = number
  default     = 80
}
