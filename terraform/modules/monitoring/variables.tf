# Monitoring Module Variables

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "instance_id" {
  description = "OCID of the application instance to monitor"
  type        = string
}

variable "db_instance_id" {
  description = "OCID of the database instance to monitor"
  type        = string
}

variable "notification_email" {
  description = "Email address for alarm notifications"
  type        = string
  default     = ""
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization percentage threshold for alarms"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory utilization percentage threshold for alarms"
  type        = number
  default     = 85
}

variable "disk_alarm_threshold" {
  description = "Disk utilization percentage threshold for alarms"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
