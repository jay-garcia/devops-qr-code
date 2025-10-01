terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.3"  # compatible with module 32.x
    }
  }
  required_version = ">= 1.4.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# -----------------------------
# VPC
# -----------------------------
resource "google_compute_network" "main" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

# -----------------------------
# Subnets in different zones
# -----------------------------
resource "google_compute_subnetwork" "subnet_b" {
  name          = "gke-subnet-b"
  ip_cidr_range = "10.0.0.0/20"
  region        = "us-east1"
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

resource "google_compute_subnetwork" "subnet_c" {
  name          = "gke-subnet-c"
  ip_cidr_range = "10.3.0.0/20"
  region        = "us-east1"
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

resource "google_compute_subnetwork" "subnet_d" {
  name          = "gke-subnet-d"
  ip_cidr_range = "10.6.0.0/20"
  region        = "us-east1"
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
# Regional GKE Cluster
# -----------------------------
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "33.0.0"  # pinned stable version

  project_id        = var.project_id
  name              = "tf-created-cluster"
  region            = var.region
  network           = google_compute_network.main.name
  subnetwork        = google_compute_subnetwork.subnet_b.name  # primary subnet
  ip_range_pods     = "pods-range-b"
  ip_range_services = "services-range-b"

  regional = true   # spans multiple zones in the region

  node_pools = [
    {
      name         = "default-pool-2"
      machine_type = "e2-small"
      min_count    = 1
      max_count    = 1
      disk_size_gb = 20
      disk_type    = "pd-standard"
    }
  ]
}
