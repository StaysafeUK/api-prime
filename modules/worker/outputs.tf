output "redis_host" {
  description = "The hostname or IP address of the Redis instance."
  value       = google_redis_instance.broker.host
}