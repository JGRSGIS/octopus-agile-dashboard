# Monitoring Module Outputs

output "notification_topic_id" {
  description = "OCID of the notification topic"
  value       = oci_ons_notification_topic.alerts.id
}

output "notification_topic_name" {
  description = "Name of the notification topic"
  value       = oci_ons_notification_topic.alerts.name
}

output "alarm_ids" {
  description = "Map of alarm names to OCIDs"
  value = {
    app_cpu      = oci_monitoring_alarm.app_cpu.id
    app_memory   = oci_monitoring_alarm.app_memory.id
    app_disk     = oci_monitoring_alarm.app_disk.id
    app_status   = oci_monitoring_alarm.app_status.id
    db_cpu       = oci_monitoring_alarm.db_cpu.id
    db_memory    = oci_monitoring_alarm.db_memory.id
    db_disk      = oci_monitoring_alarm.db_disk.id
    db_status    = oci_monitoring_alarm.db_status.id
  }
}
