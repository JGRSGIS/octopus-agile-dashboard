# Database Module Variables

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the instance"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the private subnet"
  type        = string
}

variable "nsg_ids" {
  description = "List of NSG OCIDs to attach"
  type        = list(string)
  default     = []
}

variable "db_instance_name" {
  description = "Display name for the database instance"
  type        = string
}

variable "shape" {
  description = "Compute shape"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs (for Flex shapes)"
  type        = number
  default     = 1
}

variable "memory_gb" {
  description = "Memory in GB (for Flex shapes)"
  type        = number
  default     = 6
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB"
  type        = number
  default     = 50
}

variable "data_volume_size_gb" {
  description = "Data volume size in GB for PostgreSQL"
  type        = number
  default     = 50
}

variable "image_id" {
  description = "OCID of the image"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
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

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "enable_backup" {
  description = "Enable automatic volume backups"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
