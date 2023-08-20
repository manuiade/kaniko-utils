//-----------------------------------------------------------------------------
// cloud-storage.tf - create bucket to store kaniko context
//-----------------------------------------------------------------------------

resource "google_storage_bucket" "kaniko_context" {
  name          = "${var.project_id}-${var.gke}"
  location      = var.gcp_region
  force_destroy = true
}