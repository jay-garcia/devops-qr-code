# Define Terraform and Provider versions
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      # Pinning to a known stable version range
      version = "~> 6.10" 
    }
  }
  required_version = ">= 1.4.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------
# VPC and Subnets
# -----------------------------
resource "google_compute_network" "main" {
  name                  = "gke-vpc"
  auto_create_subnetworks = false
}

# Subnet B
resource "google_compute_subnetwork" "subnet_b" {
  name          = "gke-subnet-b"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "pods-range-b"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services-range-b"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# Subnet C (Uses var.region implicitly)
resource "google_compute_subnetwork" "subnet_c" {
  name          = "gke-subnet-c"
  ip_cidr_range = "10.3.0.0/20"
  region        = var.region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "pods-range-c"
    ip_cidr_range = "10.4.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services-range-c"
    ip_cidr_range = "10.5.0.0/20"
  }
}

# Subnet D (Uses var.region implicitly)
resource "google_compute_subnetwork" "subnet_d" {
  name          = "gke-subnet-d"
  ip_cidr_range = "10.6.0.0/20"
  region        = var.region
  network       = google_compute_network.main.id

  secondary_ip_range {
    range_name    = "pods-range-d"
    ip_cidr_range = "10.7.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services-range-d"
    ip_cidr_range = "10.8.0.0/20"
  }
}

# -----------------------------
# Regional GKE Cluster (Module)
# -----------------------------
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "~> 36.0" 

  project_id          = var.project_id
  name                = "tf-created-cluster"
  region              = var.region
  network             = google_compute_network.main.name
  subnetwork          = google_compute_subnetwork.subnet_b.name
  ip_range_pods       = "pods-range-b"
  ip_range_services   = "services-range-b"

  regional = true

  release_channel = "STABLE"

  # 1. Cluster-Level Workload Identity Activation
  identity_namespace = "${var.project_id}.svc.id.goog"

}

# -----------------------------
# Custom Node Pool (Standalone Resource)
# -----------------------------
resource "google_container_node_pool" "default_pool_2" {
  cluster  = module.gke.name 
  location = var.region # Region for a regional cluster node pool
  name     = "default-pool-2"

  node_count = 1

  node_config {
    machine_type = "e2-small"
    disk_size_gb = 20
    disk_type    = "pd-standard"

    # 2. Node-Level Workload Identity Metadata Mode
    # Use the validated string that passed local validation
    workload_metadata_config {
      mode = "GKE_METADATA" 
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only", # <-- Add this line
    ]
    
    # 3. CRITICAL: Explicitly set the node service account to the default Compute SA.
    # The Workload Identity module defaults to this, and explicitly setting it
    # resolves latent conflicts when manually defining workload_metadata_config.
    service_account = module.gke.service_account # Uses the SA created/managed by the GKE module
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 1
  }

  # Define zones for this regional node pool
  node_locations = ["${var.region}-b", "${var.region}-c", "${var.region}-d"] 
}

# -----------------------------
# Firewall Rule: Allow Egress (Outbound) for GKE Nodes
# FIX for 403 Image Pull Error
# -----------------------------
resource "google_compute_firewall" "allow_gke_egress" {
  name      = "gke-allow-all-egress"
  network   = google_compute_network.main.name
  direction = "EGRESS"
  
  # Allow all protocols and ports outbound
  allow {
    protocol = "all"
  }

  # Allow all internal IPs to reach any destination
  destination_ranges = ["0.0.0.0/0"] 
  
  # Target the GKE nodes using the tag provided by the GKE module
  target_service_accounts = [module.gke.service_account]
}


# -----------------------------
# Firewall Rule: Allow SSH Ingress
# FIX for SSH Failure
# -----------------------------
resource "google_compute_firewall" "allow_ssh" {
  name    = "gke-allow-ssh-ingress"
  network = google_compute_network.main.name
  direction = "INGRESS"
  
  # Allow incoming SSH traffic (TCP port 22)
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Allow SSH from any IP (0.0.0.0/0) for simplicity in testing.
  # For production, restrict this to your specific IP or network.
  source_ranges = ["0.0.0.0/0"] 
  
  # Target the GKE nodes
  target_service_accounts = [module.gke.service_account]
}