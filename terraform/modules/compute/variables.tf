# Compute Module Variables

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the instance"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet"
  type        = string
}

variable "nsg_ids" {
  description = "List of NSG OCIDs to attach"
  type        = list(string)
  default     = []
}

variable "instance_name" {
  description = "Display name for the instance"
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

variable "image_id" {
  description = "OCID of the image"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "cloud_init_script" {
  description = "Cloud-init script content"
  type        = string
  default     = ""
}

variable "create_data_volume" {
  description = "Create additional block volume for data"
  type        = bool
  default     = false
}

variable "data_volume_size_gb" {
  description = "Size of additional data volume in GB"
  type        = number
  default     = 100
}

variable "enable_boot_volume_backup" {
  description = "Enable automatic boot volume backups"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
