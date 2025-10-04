terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

resource "google_redis_instance" "broker" {
  name           = var.redis_name
  tier           = var.redis_tier
  memory_size_gb = 1.0
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
  tags         = concat([var.vm-name, "celery-worker", "http-server", "django-api", "allow-ssh", "allow-dns-egress-dev", "allow-internet-egress-dev"], var.vm_tags)

  lifecycle {
    ignore_changes = [
      metadata["ssh-keys"],
    ]
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral external IP
    }
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  metadata = {
    api-server-ip = var.api_server_ip
    redis-host    = google_redis_instance.broker.host
  }

  metadata_startup_script = <<-EOF
  #!/bin/bash
set -ex

# Log all output to a file
exec &> /var/log/startup-celery.log

# Install dependencies
apt-get update
apt-get install -y python3-pip git python3-venv google-cloud-sdk

# 2. Install New Relic Agent.
NEW_RELIC_API_KEY=$(gcloud secrets versions access latest --secret="new-relic-api-key" --project="archejreterra")
curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY=$NEW_RELIC_API_KEY NEW_RELIC_ACCOUNT_ID=3547995 NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y



# Fetch Git Credentials
GIT_USER=$(gcloud secrets versions access latest --secret="git-user" --project="archejreterra")
GIT_PAT=$(gcloud secrets versions access latest --secret="git-pat" --project="archejreterra")

# Clone the repository
git clone --branch primeworker "https://$GIT_USER:$GIT_PAT@github.com/StaysafeUK/api-prime.git" /srv/prime-number-api

# Setup Virtual Environment
rm -rf /srv/prime-number-api/venv
python3 -m venv /srv/prime-number-api/venv

# Install Python dependencies for the worker
/srv/prime-number-api/venv/bin/pip install --no-cache-dir -r /srv/prime-number-api/requirements.txt

# Get the Redis host IP address from metadata and set it as an environment variable
export REDIS_HOST=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/redis-host)

# Start Celery worker in the background
cd /srv/prime-number-api/divisible_api
/srv/prime-number-api/venv/bin/celery -A divisible_api.celery_app worker --loglevel=info &
EOF

}

resource "google_compute_firewall" "allow_new_relic_egress" {
  name    = "${var.vm-name}-worker-allow-new-relic-egress"
  network = "default"
  direction = "EGRESS"
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  destination_ranges = [
    "162.247.240.0/22",
    "152.38.128.0/19",
    "185.221.84.0/22",
    "212.32.0.0/20",
    "64.251.192.0/20"
  ]
}
