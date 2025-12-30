# Octopus Agile Dashboard - Terraform Outputs

# ============================================================================
# Network Outputs
# ============================================================================

output "vcn_id" {
  description = "OCID of the created VCN"
  value       = module.network.vcn_id
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = module.network.private_subnet_id
}

# ============================================================================
# Compute Outputs
# ============================================================================

output "app_instance_id" {
  description = "OCID of the application instance"
  value       = module.compute.instance_id
}

output "app_public_ip" {
  description = "Public IP address of the application server"
  value       = module.compute.public_ip
}

output "app_private_ip" {
  description = "Private IP address of the application server"
  value       = module.compute.private_ip
}

# ============================================================================
# Database Outputs
# ============================================================================

output "db_instance_id" {
  description = "OCID of the database instance"
  value       = module.database.instance_id
}

output "db_private_ip" {
  description = "Private IP address of the database server"
  value       = module.database.db_private_ip
}

output "database_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql+asyncpg://${var.db_user}:****@${module.database.db_private_ip}:5432/${var.db_name}"
}

# ============================================================================
# Access Information
# ============================================================================

output "ssh_command" {
  description = "SSH command to connect to the application server"
  value       = "ssh -i <private_key> ubuntu@${module.compute.public_ip}"
}

output "application_url" {
  description = "URL to access the application"
  value       = var.app_domain != "" ? "https://${var.app_domain}" : "http://${module.compute.public_ip}"
}

output "api_docs_url" {
  description = "URL to access the API documentation"
  value       = var.app_domain != "" ? "https://${var.app_domain}/api/docs" : "http://${module.compute.public_ip}/api/docs"
}

# ============================================================================
# SSH Key (if generated)
# ============================================================================

output "generated_ssh_private_key" {
  description = "Generated SSH private key (save this securely!)"
  value       = var.ssh_public_key == "" ? tls_private_key.ssh[0].private_key_pem : "SSH key was provided externally"
  sensitive   = true
}

output "generated_ssh_public_key" {
  description = "Generated SSH public key"
  value       = var.ssh_public_key == "" ? tls_private_key.ssh[0].public_key_openssh : var.ssh_public_key
}

# ============================================================================
# Secrets (if vault enabled)
# ============================================================================

output "vault_id" {
  description = "OCID of the OCI Vault (if enabled)"
  value       = var.enable_vault ? module.secrets[0].vault_id : "Vault not enabled"
}

# ============================================================================
# Monitoring
# ============================================================================

output "monitoring_topic_id" {
  description = "OCID of the notification topic (if monitoring enabled)"
  value       = var.enable_monitoring ? module.monitoring[0].notification_topic_id : "Monitoring not enabled"
}

# ============================================================================
# Quick Start Guide
# ============================================================================

output "quick_start" {
  description = "Quick start instructions"
  value       = <<-EOT

    ═══════════════════════════════════════════════════════════════════════════
    🎉 Octopus Agile Dashboard Deployment Complete!
    ═══════════════════════════════════════════════════════════════════════════

    1. Save the SSH private key (if generated):
       terraform output -raw generated_ssh_private_key > agile-dashboard.pem
       chmod 600 agile-dashboard.pem

    2. Connect to your server:
       ssh -i agile-dashboard.pem ubuntu@${module.compute.public_ip}

    3. Access the application:
       Dashboard: http://${module.compute.public_ip}
       API Docs:  http://${module.compute.public_ip}/api/docs

    4. Check application status:
       ssh -i agile-dashboard.pem ubuntu@${module.compute.public_ip} 'docker-compose -f /opt/app/docker-compose.yml ps'

    5. View logs:
       ssh -i agile-dashboard.pem ubuntu@${module.compute.public_ip} 'docker-compose -f /opt/app/docker-compose.yml logs -f'

    ═══════════════════════════════════════════════════════════════════════════
  EOT
}
