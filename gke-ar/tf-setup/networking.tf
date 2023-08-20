//-----------------------------------------------------------------------------
// networking.tf - create the VPC and subnet
//-----------------------------------------------------------------------------

// VPC creation
resource "google_compute_network" "gke_vpc" {
  name                    = var.gke
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  project                 = var.project_id
}


// Subnet creation
resource "google_compute_subnetwork" "gke_subnetwork" {
  name                     = var.gke
  ip_cidr_range            = "10.10.0.0/24"
  region                   = var.gcp_region
  private_ip_google_access = true
  network                  = google_compute_network.gke_vpc.name
  project                  = var.project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.100.0.0/16"
  }

  secondary_ip_range {
    range_name    = "svcs"
    ip_cidr_range = "10.101.0.0/24"
  }
}


// Create a NAT router for dynamic routes
resource "google_compute_router" "gke_nat_router" {
  name    = var.gke
  region  = var.gcp_region
  network = google_compute_network.gke_vpc.name
  project = var.project_id
}


// Create the Source NAT gateway
resource "google_compute_router_nat" "gke_nat_gateway" {
  name                               = var.gke
  router                             = google_compute_router.gke_nat_router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  project                            = var.project_id
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}