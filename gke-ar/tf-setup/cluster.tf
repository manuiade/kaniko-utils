//-----------------------------------------------------------------------------
// cluster.tf - create GKE cluster with dedicated nodepool and service account
//-----------------------------------------------------------------------------


resource "google_service_account" "cluster_service_account" {
  project      = var.project_id
  account_id   = var.gke
  display_name = "Service account for cluster gke-cluster"
}

resource "google_project_iam_member" "project_sa_roles" {
  count   = length(local.sa_roles) > 0 ? length(local.sa_roles) : 0
  project = var.project_id
  role    = element(local.sa_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.cluster_service_account.email)
}

resource "google_container_cluster" "gke_primary" {
  provider = google-beta

  // General
  name           = var.gke
  project        = var.project_id
  location       = var.gcp_zone

  // Networking
  //cluster_ipv4_cidr = var.cluster_ipv4_cidr
  network    = google_compute_network.gke_vpc.name
  subnetwork = google_compute_subnetwork.gke_subnetwork.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "svcs"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "Home"
    }
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
    master_global_access_config {
      enabled = true
    }
  }

  // Nodepool settings
  initial_node_count       = 1
  remove_default_node_pool = true

  node_config {
    shielded_instance_config {
      enable_secure_boot = true
    }
  }

  // Security
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

// Nodepool creation
resource "google_container_node_pool" "nodepools" {
  provider = google-beta
  name     = "primary-pool"
  project  = var.project_id
  location = var.gcp_zone
  cluster  = google_container_cluster.gke_primary.name

  // General
  node_locations    = var.gcp_zones
  max_pods_per_node = 32

  // Scaling
  node_count         = 3

  node_config {

    // GCE configuration
    image_type   = "COS_CONTAINERD"
    machine_type = "e2-standard-2"

    // Node security
    service_account = google_service_account.cluster_service_account.email
    preemptible     = true

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    metadata = {
      "disable-legacy-endpoints" = "true"
    }
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}


### add workload identity