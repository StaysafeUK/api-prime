variable "redis_name" {
  description = "The name of the Redis instance."
  type        = string
  default     = "celery-redis-broker"
}

variable "redis_tier" {
  description = "The service tier of the instance. "
  type        = string
  default     = "BASIC"
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "europe-west1"
}

variable "cloud_project" {
  description = "The GCP project ID."
  type        = string
}

variable "celery_worker_count" {
  description = "The number of Celery worker instances to create."
  type        = number
  default     = 1
}

variable "vm-name" {
  description = "The base name for the VM instances."
  type        = string
  default     = "api-prime"
}

variable "vm_tags" {
  description = "A list of tags to apply to the VM instances."
  type        = list(string)
  default     = []
}

variable "api_server_name" {
  description = "The name of the API server instance to connect to."
  type        = string
  default     = "api-frontend-0"
}