# Network Module Variables

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "vcn_cidr_block" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_display_name" {
  description = "Display name for the VCN"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_domain" {
  description = "Availability domain for subnets"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the VCN"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
