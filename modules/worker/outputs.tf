
output "redis_host" {
  value = google_redis_instance.broker.host
}

output "redis_port" {
  value = google_redis_instance.broker.port
}
