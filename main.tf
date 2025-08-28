provider "google" {
  # credentials = file("credentials.json")
  project     = "${var.cloud_project}"
  region      = "europe-west1"
  zone        = "europe-west1-b"
}

terraform {
  required_version = ">= 1.0.11"
  required_providers {
    google = {


      source  = "hashicorp/google"
      version = ">= 4.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
  }
}

resource "google_project_iam_member" "redis_permission" {
  project = var.cloud_project
  role    = "roles/redis.editor"
  member  = "serviceAccount:754166336149-compute@developer.gserviceaccount.com"
}

resource "google_project_service" "redis_api" {
  project            = var.cloud_project
  service            = "redis.googleapis.com"
  disable_on_destroy = false
}

variable "cloud_project" {
  description = "The GCP project ID."
  type        = string
}

variable "git_user" {
  description = "The GitHub username for cloning the private repository."
  type        = string
  default     = "jrevans"
}

variable "git_project" {
  description = "The GitHub project name to be cloned."
  type        = string
  default     = "api-prime"
}

variable "git_pat" {
  description = "The Personal Access Token for cloning the private Git repository."
  type        = string
  sensitive   = true
}

variable "instance_count" {
  description = "The number of VM instances to create."
  type        = number
  default     = 1
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "europe-west1"
}

variable "domain_name" {
  description = "The domain name for the SSL certificate."
  type        = string
  default     = "api-prime.example.com"
}

variable "celery_worker_count" {
  description = "The number of Celery worker instances to create."
  type        = number
  default     = 1
}

module "vm" {
  source           = "./modules/vm"
  vm-name          = "api-frontend"
  git_user         = var.git_user
  git_pat          = var.git_pat
  git_project      = var.git_project
  cloud_project    = var.cloud_project
  instance_count   = var.instance_count
  region           = var.region
  domain_name      = var.domain_name
}

module "worker" {
  source              = "./modules/worker"
  cloud_project       = var.cloud_project
  region              = var.region
  api_server_ip       = module.vm.ip[0]
  celery_worker_count = var.celery_worker_count
  vm-name             = "api-frontend"
  vm_tags             = ["api-frontend", "celery-worker"]

  providers = {
    google = google
  }

  depends_on = [google_project_service.redis_api]
}

resource "local_file" "IPs" {
  filename = "./inventory.csv"
  content  = templatefile("manifest.tftpl", { ip_addrs = flatten(module.vm.*.external_ip) })
}

data "external" "firewall_exists" {
  program = ["bash", "-c", "gcloud compute firewall-rules describe allow-http-8000 --project=${var.cloud_project} >/dev/null 2>&1 && echo '{\"exists\": \"true\"}' || echo '{\"exists\": \"false\"}'"]
}

resource "google_compute_firewall" "allow-http-8000" {
  count   = data.external.firewall_exists.result.exists == "true" ? 0 : 1
  name    = "allow-http-8000"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
}
