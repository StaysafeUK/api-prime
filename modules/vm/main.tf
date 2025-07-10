variable "vm-name" {
  description = "api-prime"
}

variable "git_pat" {
  description = "The Personal Access Token for cloning the private Git repository."
  type        = string
  sensitive   = true
}

resource "google_secret_manager_secret" "git-pat-secret" {
  project   = "archejreterra" # IMPORTANT: Replace with your GCP Project ID
  secret_id = "git-pat"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "git-pat-secret-version" {
  secret      = google_secret_manager_secret.git-pat-secret.id
  secret_data = var.git_pat
}

resource "google_compute_instance" "vm" {
  name         = var.vm-name
  machine_type = "n1-standard-2"
  zone         = "europe-west1-b"

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

  metadata_startup_script = <<-EOF
    #!/bin/bash -e
    # Exit immediately if a command exits with a non-zero status.
    set -e

    # Update and install packages
    apt-get update
    apt-get install -y python3-pip git python3-venv google-cloud-sdk

    # --- Fetch Git Credentials ---
    echo "Fetching Git PAT from Secret Manager..."
    GIT_PAT=$(gcloud secrets versions access latest --secret="git-pat" --project="archejreterra") # IMPORTANT: Replace with your GCP Project ID

    # --- Clone Repository ---
    echo "Cloning private repository..."
    git clone "https://jrevans:${GIT_PAT}@github.com/StaysafeUK/api-prime.git" /srv/api-prime

    # --- Setup Virtual Environment ---
    echo "Setting up Python virtual environment..."
    python3 -m venv /srv/api-prime/venv
    source /srv/api-prime/venv/bin/activate

    # Install Python dependencies
    pip install -r /srv/api-prime/requirements.txt

    # --- Configure Django Project ---
    echo "Configuring Django..."
    EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    echo "External IP: $EXTERNAL_IP"
    sed -i "s/^ALLOWED_HOSTS = .*/ALLOWED_HOSTS = [\"$EXTERNAL_IP\"]/" /srv/api-prime/divisible_api/divisible_api/settings.py
    
    # --- Start Django App ---
    echo "Starting Django app..."
    cd /srv/api-prime/divisible_api
    python3 manage.py migrate
    gunicorn divisible_api.wsgi:application --bind 0.0.0.0:8000 --daemon
    echo "Gunicorn started."
    EOF
}

resource "google_compute_firewall" "allow-http-8000" {
  name    = "allow-http-8000"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

output "ip" {
  value = google_compute_instance.vm.network_interface[0].network_ip
}

output "external_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}
