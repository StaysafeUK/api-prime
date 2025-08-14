provider "google" {
  project = var.cloud_project
  region  = var.region
}

data "google_compute_instance" "api_server" {
  name    = var.api_server_name
  zone    = "europe-west1-b"
  project = var.cloud_project
}

resource "google_redis_instance" "broker" {
  name           = var.redis_name
  tier           = var.redis_tier
  memory_size_gb = 1
  region         = var.region
  redis_version  = "REDIS_5_0"

  maintenance_policy {
    weekly_maintenance_window {
      day = "SATURDAY"
      start_time {
        hours   = 0
        minutes = 30
        seconds = 0
        nanos   = 0
      }
    }
  }
}

resource "google_compute_instance" "celery_worker" {
  count        = var.celery_worker_count
  name         = "${var.vm-name}-celery-worker-${count.index}"
  machine_type = "n1-standard-1"
  zone         = "europe-west1-b"
  tags         = concat([var.vm-name, "celery-worker"], var.vm_tags)

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata = {
    api-server-ip = data.google_compute_instance.api_server.network_interface[0].network_ip
    redis-host    = google_redis_instance.broker.host
  }

  metadata_startup_script = <<-EOF
  #!/bin/bash
set -ex

# Install dependencies
apt-get update
apt-get install -y python3-pip git

# Clone the repository
git clone https://github.com/StaysafeUK/prime-number-api.git /srv/prime-number-api

# Install Python dependencies for the worker
pip3 install -r /srv/prime-number-api/modules/worker/requirements.txt

# Get the Redis host IP address from metadata
REDIS_HOST=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/redis-host)

# Update the Celery configuration in Django settings
sed -i "s/<REDIS_IP_ADDRESS>/$REDIS_HOST/" /srv/prime-number-api/divisible_api/settings.py

# Start Celery worker in the background
cd /srv/prime-number-api/divisible_api
nohup celery -A divisible_api worker --loglevel=info &
EOF

}