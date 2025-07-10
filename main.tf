provider "google" {
  credentials = file("credentials.json")
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

variable "vm_names" {
  type    = list(string)
  default = ["api-front-end"]
}

variable "git_user" {
  description = "The GitHub username for cloning the private repository."
  type        = string
  default     = "jrevans"
}

variable "git_pat" {
  description = "The Personal Access Token for cloning the private Git repository."
  type        = string
  sensitive   = true
}

variable "git_project" {
  description = "The GitHub project name to be cloned."
  type        = string
  default     = "api-prime"
}

variable "cloud_project" {
  description = "The GCP project ID."
  type        = string
}

module "vm" {
  source        = "./modules/vm"
  vm-name       = var.vm_names[count.index]
  git_user      = var.git_user
  git_pat       = var.git_pat
  git_project   = var.git_project
  cloud_project = var.cloud_project
  count         = length(var.vm_names)
}

resource "local_file" "IPs" {
  filename = "./inventory.csv"
  content  = templatefile("manifest.tftpl", { ip_addrs = module.vm.*.ip })
}