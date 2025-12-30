# Network Module - VCN, Subnets, Gateways, and Security Groups

# ============================================================================
# Virtual Cloud Network (VCN)
# ============================================================================

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.vcn_cidr_block]
  display_name   = var.vcn_display_name
  dns_label      = replace(var.project_name, "-", "")
  is_ipv6enabled = var.enable_ipv6

  freeform_tags = var.tags
}

# ============================================================================
# Internet Gateway (for public subnet)
# ============================================================================

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-igw"
  enabled        = true

  freeform_tags = var.tags
}

# ============================================================================
# NAT Gateway (for private subnet outbound access)
# ============================================================================

resource "oci_core_nat_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-nat-gw"
  block_traffic  = false

  freeform_tags = var.tags
}

# ============================================================================
# Service Gateway (for OCI services access)
# ============================================================================

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-service-gw"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }

  freeform_tags = var.tags
}

# ============================================================================
# Route Tables
# ============================================================================

# Public route table (routes to internet)
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }

  freeform_tags = var.tags
}

# Private route table (routes through NAT)
resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.main.id
  }

  freeform_tags = var.tags
}

# ============================================================================
# Security Lists
# ============================================================================

# Public security list (for app server)
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-public-sl"

  # Egress - allow all outbound
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Ingress - SSH
  dynamic "ingress_security_rules" {
    for_each = var.allowed_ssh_cidrs
    content {
      source    = ingress_security_rules.value
      protocol  = "6"  # TCP
      stateless = false

      tcp_options {
        min = 22
        max = 22
      }
    }
  }

  # Ingress - HTTP
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "6"  # TCP
    stateless = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  # Ingress - HTTPS
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "6"  # TCP
    stateless = false

    tcp_options {
      min = 443
      max = 443
    }
  }

  # Ingress - ICMP (ping)
  ingress_security_rules {
    source    = "0.0.0.0/0"
    protocol  = "1"  # ICMP
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  ingress_security_rules {
    source    = var.vcn_cidr_block
    protocol  = "1"
    stateless = false

    icmp_options {
      type = 3
    }
  }

  freeform_tags = var.tags
}

# Private security list (for database)
resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-private-sl"

  # Egress - allow all outbound through NAT
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  # Ingress - PostgreSQL from public subnet only
  ingress_security_rules {
    source    = var.public_subnet_cidr
    protocol  = "6"  # TCP
    stateless = false

    tcp_options {
      min = 5432
      max = 5432
    }
  }

  # Ingress - SSH from public subnet (for management)
  ingress_security_rules {
    source    = var.public_subnet_cidr
    protocol  = "6"  # TCP
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress - ICMP from VCN
  ingress_security_rules {
    source    = var.vcn_cidr_block
    protocol  = "1"
    stateless = false

    icmp_options {
      type = 3
    }
  }

  freeform_tags = var.tags
}

# ============================================================================
# Subnets
# ============================================================================

# Public subnet (for application server)
resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "${var.project_name}-public-subnet"
  dns_label                  = "public"
  availability_domain        = var.availability_domain
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]

  freeform_tags = var.tags
}

# Private subnet (for database)
resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.main.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "${var.project_name}-private-subnet"
  dns_label                  = "private"
  availability_domain        = var.availability_domain
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]

  freeform_tags = var.tags
}

# ============================================================================
# Network Security Groups (NSGs) - More granular security
# ============================================================================

# Application NSG
resource "oci_core_network_security_group" "app" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-app-nsg"

  freeform_tags = var.tags
}

# App NSG Rules
resource "oci_core_network_security_group_security_rule" "app_egress" {
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "app_ingress_http" {
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "app_ingress_https" {
  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "app_ingress_ssh" {
  for_each = toset(var.allowed_ssh_cidrs)

  network_security_group_id = oci_core_network_security_group.app.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = each.value
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

# Database NSG
resource "oci_core_network_security_group" "db" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${var.project_name}-db-nsg"

  freeform_tags = var.tags
}

# DB NSG Rules
resource "oci_core_network_security_group_security_rule" "db_egress" {
  network_security_group_id = oci_core_network_security_group.db.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group_security_rule" "db_ingress_postgres" {
  network_security_group_id = oci_core_network_security_group.db.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.app.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

resource "oci_core_network_security_group_security_rule" "db_ingress_ssh" {
  network_security_group_id = oci_core_network_security_group.db.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.app.id
  source_type               = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}
