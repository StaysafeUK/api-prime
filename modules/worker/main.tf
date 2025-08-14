provider "google" {
  project = var.cloud_project
  region  = var.region
}

data "google_compute_instance" "api_server" {
  name    = "api-prime-0"
  zone    = "europe-west1-b"
  project = var.cloud_project
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
  }

  metadata_startup_script = <<-EOF
  #!/bin/bash
set -ex

# Install dependencies
apt-get update
apt-get install -y python3-pip git

# Clone the repository
git clone https://github.com/StaysafeUK/prime-number-api.git /srv/prime-number-api

# Install Python dependencies
pip3 install -r /srv/prime-number-api/requirements.txt

# Get the API server IP address from metadata
API_SERVER_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/api-server-ip)

# Update the Celery configuration
sed -i "s/<REDIS_IP_ADDRESS>/$API_SERVER_IP/" /srv/prime-number-api/divisible_api/settings.py

# Start Celery worker
cd /srv/prime-number-api/divisible_api
celery -A divisible_api worker --loglevel=info
EOF

}