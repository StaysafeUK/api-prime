variable "vm-name" {
  description = "The base name for the virtual machines."
  type        = string
  default     = "api-prime"
}

variable "cloud_project" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "europe-west1"
}

variable "vm_tags" {
  description = "A list of tags to apply to the VM instances."
  type        = list(string)
  default     = []
}

variable "celery_worker_count" {
  description = "The number of Celery worker instances to create."
  type        = number
  default     = 1
  validation {
    condition     = var.celery_worker_count >= 1 && var.celery_worker_count <= 10
    error_message = "The number of Celery workers must be between 1 and 10."
  }
}