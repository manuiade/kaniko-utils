//-----------------------------------------------------------------------------
// providers.tf - contain the definition of TF configuration
//-----------------------------------------------------------------------------


terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.12"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.12"
    }
  }
  required_version = "~> 1.2.0"
}

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}