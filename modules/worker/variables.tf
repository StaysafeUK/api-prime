
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
