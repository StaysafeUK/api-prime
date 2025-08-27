variable "api_server_ip" {
  description = "The private IP address of the API server."
  type        = string
}

variable "cloud_project" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
}

variable "celery_worker_count" {
  description = "The number of Celery worker instances to create."
  type        = number
}

variable "redis_name" {
  description = "The name of the Redis instance."
  type        = string
  default     = "redis-broker"
}

variable "redis_tier" {
  description = "The service tier of the Redis instance."
  type        = string
  default     = "BASIC"
}

variable "vm-name" {
  description = "The base name for the VM."
  type        = string
  default     = "api-frontend"
}

variable "vm_tags" {
  description = "A list of tags to apply to the VM instances."
  type        = list(string)
  default     = []
}