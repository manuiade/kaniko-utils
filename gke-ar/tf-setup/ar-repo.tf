//-----------------------------------------------------------------------------
// ar-repo.tf - create AR repo for storing docker images
//-----------------------------------------------------------------------------

resource "google_artifact_registry_repository" "ar_repo" {
  location      = var.gcp_region
  repository_id = var.gke
  format        = "DOCKER"
  project = var.project_id
}