variable "gcp_region" {
  type    = string
  default = "europe-west1"
}

variable "gcp_zone" {
  type    = string
  default = "europe-west1-c"
}

variable "gcp_zones" {
  type    = list(string)
  default = ["europe-west1-c"]
}

variable "project_id" {
  type    = string
}


variable "gke" {
  type = string
}