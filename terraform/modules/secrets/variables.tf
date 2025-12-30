# Secrets Module Variables

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "vault_name" {
  description = "Display name for the vault"
  type        = string
}

variable "key_name" {
  description = "Display name for the master key"
  type        = string
}

variable "secrets" {
  description = "Map of secret names to values"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
