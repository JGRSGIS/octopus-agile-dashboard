# Octopus Agile Dashboard - Oracle Cloud Infrastructure Deployment

This Terraform/OpenTofu configuration deploys the Octopus Agile Dashboard to Oracle Cloud Infrastructure (OCI), taking advantage of the **Always Free Tier** resources.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              OCI Region                                  │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    Virtual Cloud Network (VCN)                     │  │
│  │                         10.0.0.0/16                                │  │
│  │  ┌─────────────────────────┐  ┌─────────────────────────────────┐ │  │
│  │  │    Public Subnet        │  │      Private Subnet              │ │  │
│  │  │     10.0.1.0/24         │  │       10.0.2.0/24                │ │  │
│  │  │                         │  │                                   │ │  │
│  │  │  ┌──────────────────┐   │  │   ┌──────────────────────────┐  │ │  │
│  │  │  │  App Server      │   │  │   │  Database Server          │  │ │  │
│  │  │  │  (A1.Flex)       │───┼──┼──▶│  (A1.Flex)                │  │ │  │
│  │  │  │                  │   │  │   │                            │  │ │  │
│  │  │  │  - Docker        │   │  │   │  - PostgreSQL 14          │  │ │  │
│  │  │  │  - Nginx         │   │  │   │  - Data Volume            │  │ │  │
│  │  │  │  - React App     │   │  │   │  - Auto Backups           │  │ │  │
│  │  │  │  - FastAPI       │   │  │   │                            │  │ │  │
│  │  │  │  - Redis         │   │  │   └──────────────────────────┘  │ │  │
│  │  │  └──────────────────┘   │  │                                   │ │  │
│  │  │           │             │  │                                   │ │  │
│  │  └───────────┼─────────────┘  └───────────────────────────────────┘ │  │
│  │              │                                                       │  │
│  │      ┌───────▼───────┐    ┌──────────────┐    ┌──────────────────┐  │  │
│  │      │ Internet GW   │    │  NAT Gateway │    │ Service Gateway  │  │  │
│  │      └───────────────┘    └──────────────┘    └──────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │   OCI Vault     │  │  Monitoring     │  │   Notifications             │  │
│  │   (Optional)    │  │  & Alarms       │  │   (Email Alerts)            │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

## Free Tier Resources

This configuration is designed to fit within OCI's Always Free Tier:

| Resource | Free Tier Limit | This Config |
|----------|-----------------|-------------|
| ARM Compute (A1.Flex) | 4 OCPUs, 24GB RAM total | 2 OCPUs, 12GB RAM |
| Boot Volumes | 200GB total | 100GB total |
| Block Volumes | 200GB total | 50GB for DB data |
| Outbound Data | 10TB/month | Minimal |
| Object Storage | 20GB | Not used |
| VCN | 2 VCNs | 1 VCN |

## Prerequisites

1. **OCI Account** with Always Free Tier
2. **OCI CLI** installed and configured
3. **Terraform** (>= 1.0) or **OpenTofu** (>= 1.6)
4. **Octopus Energy Account** with API access

### Setting Up OCI CLI

```bash
# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configure OCI CLI
oci setup config

# Test configuration
oci iam region list
```

### Getting OCI Credentials

1. Log into [OCI Console](https://cloud.oracle.com)
2. Click your profile icon → **User Settings**
3. Note your **User OCID**
4. Go to **Tenancy Details** (from main menu) and note the **Tenancy OCID**
5. Under **API Keys**, click **Add API Key**
6. Download the private key and note the **Fingerprint**

## Quick Start

### 1. Clone and Configure

```bash
cd terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### 2. Required Variables

Edit `terraform.tfvars` with your values:

```hcl
# OCI Authentication
tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaa..."
user_ocid        = "ocid1.user.oc1..aaaaaa..."
fingerprint      = "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
private_key_path = "~/.oci/oci_api_key.pem"
compartment_ocid = "ocid1.compartment.oc1..aaaaaa..."
region           = "uk-london-1"

# Octopus Energy API
octopus_api_key       = "sk_live_xxxx"
octopus_mpan          = "2000000000000"
octopus_serial_number = "00A0000000"
octopus_region        = "H"
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy (takes ~10-15 minutes)
terraform apply
```

### 4. Access Your Dashboard

After deployment, Terraform will output:

```
Outputs:

app_public_ip = "xxx.xxx.xxx.xxx"
application_url = "http://xxx.xxx.xxx.xxx"
api_docs_url = "http://xxx.xxx.xxx.xxx/api/docs"
ssh_command = "ssh -i <private_key> ubuntu@xxx.xxx.xxx.xxx"
```

## Module Structure

```
terraform/
├── main.tf                    # Root module - orchestrates all modules
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider version constraints
├── terraform.tfvars.example   # Example configuration
│
├── modules/
│   ├── network/               # VCN, subnets, security groups
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/               # Application server instance
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── database/              # PostgreSQL server instance
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── secrets/               # OCI Vault (optional)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── monitoring/            # Alarms and notifications
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── scripts/
    └── cloud-init.yaml        # Instance initialization script
```

## Configuration Options

### Compute Shapes

| Shape | Type | Free Tier | Notes |
|-------|------|-----------|-------|
| `VM.Standard.A1.Flex` | ARM Ampere | ✅ | Recommended, up to 4 OCPUs/24GB |
| `VM.Standard.E2.1.Micro` | AMD | ✅ | 1/8 OCPU, 1GB RAM |
| `VM.Standard.E4.Flex` | AMD EPYC | ❌ | Paid |
| `VM.Standard3.Flex` | Intel | ❌ | Paid |

### Networking

Default CIDR blocks:
- VCN: `10.0.0.0/16`
- Public Subnet: `10.0.1.0/24`
- Private Subnet: `10.0.2.0/24`

### Security

By default, the configuration:
- Restricts database access to the application server only
- Allows SSH from anywhere (customize `allowed_ssh_cidrs`)
- Enables HTTPS (port 443)
- Uses NSGs for fine-grained security

**Production Recommendations:**

```hcl
# Restrict SSH to your IP only
allowed_ssh_cidrs = ["YOUR_IP/32"]

# Enable Vault for secrets
enable_vault = true

# Enable SSL
enable_ssl = true
app_domain = "your-domain.com"
admin_email = "admin@your-domain.com"
```

## Post-Deployment

### SSH Access

```bash
# Save the generated SSH key
terraform output -raw generated_ssh_private_key > agile-dashboard.pem
chmod 600 agile-dashboard.pem

# Connect to app server
ssh -i agile-dashboard.pem ubuntu@$(terraform output -raw app_public_ip)

# Connect to database server (via app server)
ssh -i agile-dashboard.pem -J ubuntu@$(terraform output -raw app_public_ip) ubuntu@$(terraform output -raw db_private_ip)
```

### View Application Logs

```bash
ssh -i agile-dashboard.pem ubuntu@$(terraform output -raw app_public_ip) \
  'docker-compose -f /opt/app/docker-compose.yml logs -f'
```

### Update Application

```bash
ssh -i agile-dashboard.pem ubuntu@$(terraform output -raw app_public_ip) << 'EOF'
cd /opt/app
git pull
docker-compose pull
docker-compose up -d --build
EOF
```

### Database Backup

```bash
ssh -i agile-dashboard.pem ubuntu@$(terraform output -raw app_public_ip) << 'EOF'
ssh $(terraform output -raw db_private_ip) \
  'pg_dump -U octopus octopus_agile > /tmp/backup.sql'
EOF
```

## Monitoring & Alerts

When `enable_monitoring = true`, the following alarms are created:

| Alarm | Threshold | Severity |
|-------|-----------|----------|
| CPU High | > 80% | Critical |
| Memory High | > 85% | Critical |
| Disk High | > 80% | Warning |
| Instance Down | No response | Critical |

Configure email alerts by setting `admin_email` in your `terraform.tfvars`.

## Cost Optimization

This configuration is designed for the free tier, but here are additional tips:

1. **Use ARM instances** (A1.Flex) - more efficient than AMD
2. **Right-size resources** - start with 1 OCPU, scale up if needed
3. **Monitor usage** - check OCI Cost Analysis dashboard
4. **Clean up** - destroy resources when not needed

```bash
# Destroy all resources
terraform destroy
```

## Troubleshooting

### Instance not responding

```bash
# Check instance status via OCI Console or CLI
oci compute instance get --instance-id $(terraform output -raw app_instance_id)

# View boot logs
oci compute console-history create --instance-id $(terraform output -raw app_instance_id)
```

### Application not starting

```bash
# SSH in and check logs
ssh -i agile-dashboard.pem ubuntu@$(terraform output -raw app_public_ip)

# View cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Check Docker containers
docker-compose -f /opt/app/docker-compose.yml ps
docker-compose -f /opt/app/docker-compose.yml logs
```

### Database connection issues

```bash
# From app server, test DB connectivity
nc -zv $(terraform output -raw db_private_ip) 5432

# Check PostgreSQL status
ssh ubuntu@$(terraform output -raw db_private_ip) 'sudo systemctl status postgresql'
```

## Security Considerations

1. **API Keys**: Store `terraform.tfvars` securely, don't commit to git
2. **SSH Keys**: The generated SSH key should be stored securely
3. **Database**: Only accessible from private subnet
4. **Secrets**: Consider enabling OCI Vault for production

Add to `.gitignore`:

```
terraform.tfvars
*.pem
*.tfstate
*.tfstate.backup
.terraform/
```

## License

This configuration is provided as-is under the MIT License.
