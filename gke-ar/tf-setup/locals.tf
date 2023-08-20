locals {
    sa_roles = [
        "roles/logging.logWriter",
        "roles/monitoring.metricWriter",
        "roles/artifactregistry.reader",
        "roles/artifactregistry.writer",
        "roles/storage.admin"
    ]
}