# Monitoring Module - OCI Monitoring, Alarms, and Notifications

# ============================================================================
# Notification Topic for Alerts
# ============================================================================

resource "oci_ons_notification_topic" "alerts" {
  compartment_id = var.compartment_ocid
  name           = "${var.project_name}-alerts"
  description    = "Notification topic for ${var.project_name} alerts"

  freeform_tags = var.tags
}

# ============================================================================
# Email Subscription for Alerts
# ============================================================================

resource "oci_ons_subscription" "email" {
  count = var.notification_email != "" ? 1 : 0

  compartment_id = var.compartment_ocid
  topic_id       = oci_ons_notification_topic.alerts.id
  protocol       = "EMAIL"
  endpoint       = var.notification_email

  freeform_tags = var.tags
}

# ============================================================================
# Application Server Alarms
# ============================================================================

# CPU Utilization Alarm
resource "oci_monitoring_alarm" "app_cpu" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-app-cpu-high"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_computeagent"
  query         = "CpuUtilization[5m]{resourceId = \"${var.instance_id}\"}.mean() > ${var.cpu_alarm_threshold}"
  severity      = "CRITICAL"
  body          = "Application server CPU utilization is above ${var.cpu_alarm_threshold}% for 5 minutes."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT5M"
  resolution       = "1m"
  is_enabled       = true

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}

# Memory Utilization Alarm
resource "oci_monitoring_alarm" "app_memory" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-app-memory-high"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_computeagent"
  query         = "MemoryUtilization[5m]{resourceId = \"${var.instance_id}\"}.mean() > ${var.memory_alarm_threshold}"
  severity      = "CRITICAL"
  body          = "Application server memory utilization is above ${var.memory_alarm_threshold}% for 5 minutes."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT5M"
  resolution       = "1m"
  is_enabled       = true

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}

# Disk Utilization Alarm
resource "oci_monitoring_alarm" "app_disk" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-app-disk-high"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_computeagent"
  query         = "DiskBytesUsed[5m]{resourceId = \"${var.instance_id}\"}.mean() / DiskBytesTotal[5m]{resourceId = \"${var.instance_id}\"}.mean() * 100 > ${var.disk_alarm_threshold}"
  severity      = "WARNING"
  body          = "Application server disk utilization is above ${var.disk_alarm_threshold}%."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT10M"
  resolution       = "1m"
  is_enabled       = true

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}

# Instance Status Alarm
resource "oci_monitoring_alarm" "app_status" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-app-instance-down"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_compute_infrastructure_health"
  query         = "instance_status[1m]{resourceId = \"${var.instance_id}\"}.count() == 0"
  severity      = "CRITICAL"
  body          = "Application server instance is not responding or has stopped."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT3M"
  resolution       = "1m"
  is_enabled       = true

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}

# ============================================================================
# Database Server Alarms
# ============================================================================

# Database CPU Alarm
resource "oci_monitoring_alarm" "db_cpu" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-db-cpu-high"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_computeagent"
  query         = "CpuUtilization[5m]{resourceId = \"${var.db_instance_id}\"}.mean() > ${var.cpu_alarm_threshold}"
  severity      = "CRITICAL"
  body          = "Database server CPU utilization is above ${var.cpu_alarm_threshold}% for 5 minutes."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT5M"
  resolution       = "1m"
  is_enabled       = true

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}

# Database Memory Alarm
resource "oci_monitoring_alarm" "db_memory" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-db-memory-high"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_computeagent"
  query         = "MemoryUtilization[5m]{resourceId = \"${var.db_instance_id}\"}.mean() > ${var.memory_alarm_threshold}"
  severity      = "CRITICAL"
  body          = "Database server memory utilization is above ${var.memory_alarm_threshold}% for 5 minutes."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT5M"
  resolution       = "1m"
  is_enabled       = true

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}

# Database Disk Alarm
resource "oci_monitoring_alarm" "db_disk" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-db-disk-high"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_computeagent"
  query         = "DiskBytesUsed[5m]{resourceId = \"${var.db_instance_id}\"}.mean() / DiskBytesTotal[5m]{resourceId = \"${var.db_instance_id}\"}.mean() * 100 > ${var.disk_alarm_threshold}"
  severity      = "WARNING"
  body          = "Database server disk utilization is above ${var.disk_alarm_threshold}%."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT10M"
  resolution       = "1m"
  is_enabled       = true

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}

# Database Instance Status Alarm
resource "oci_monitoring_alarm" "db_status" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-db-instance-down"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_compute_infrastructure_health"
  query         = "instance_status[1m]{resourceId = \"${var.db_instance_id}\"}.count() == 0"
  severity      = "CRITICAL"
  body          = "Database server instance is not responding or has stopped."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT3M"
  resolution       = "1m"
  is_enabled       = true

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}

# ============================================================================
# Network Alarms
# ============================================================================

# VCN Flow Log Alarm (High Rejected Connections)
resource "oci_monitoring_alarm" "network_rejected" {
  compartment_id        = var.compartment_ocid
  display_name          = "${var.project_name}-network-rejected-high"
  metric_compartment_id = var.compartment_ocid

  namespace     = "oci_vcn"
  query         = "VnicFromNetworkBytes[5m].rate() < 100"  # Placeholder - adjust based on actual needs
  severity      = "INFO"
  body          = "Network connectivity issue detected."
  message_format = "ONS_OPTIMIZED"

  pending_duration = "PT10M"
  resolution       = "1m"
  is_enabled       = false  # Disabled by default, enable as needed

  destinations = [oci_ons_notification_topic.alerts.id]

  freeform_tags = var.tags
}
