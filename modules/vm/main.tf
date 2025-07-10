variable "vm-name" {
  description = "api-prime"
}

variable "git_user" {
  description = "The GitHub username for cloning the private repository."
  type        = string
}

variable "git_pat" {
  description = "The Personal Access Token for cloning the private Git repository."
  type        = string
  sensitive   = true
}

variable "git_project" {
  description = "The GitHub project name to be cloned."
  type        = string
}

variable "cloud_project" {
  description = "The GCP project ID."
  type        = string
}

resource "google_secret_manager_secret" "git-user-secret" {
  project   = var.cloud_project
  secret_id = "git-user"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "git-user-secret-version" {
  secret      = google_secret_manager_secret.git-user-secret.id
  secret_data = var.git_user
}

resource "google_secret_manager_secret" "git-pat-secret" {
  project   = var.cloud_project
  secret_id = "git-pat"

  replication {
    auto {}
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

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Log all output to a file and the console.
    exec &> /var/log/startup.log

    set -x # Print each command before it's executed.

    echo "--- Starting Startup Script ---"

    # 1. Install only essential packages.
    apt-get update
    apt-get install -y python3-pip git python3-venv google-cloud-sdk

    # 2. Fetch Git Credentials.
    echo "Fetching Git User and PAT from Secret Manager..."
    GIT_USER=$(gcloud secrets versions access latest --secret="git-user" --project="archejreterra")
    GIT_PAT=$(gcloud secrets versions access latest --secret="git-pat" --project="archejreterra")

    # 3. Clone Repository.
    echo "Cloning private repository..."
    git clone "https://$GIT_USER:$GIT_PAT@github.com/StaysafeUK/${var.git_project}.git" /srv/api-prime

    # 4. Setup Virtual Environment.
    echo "Setting up Python virtual environment..."
    python3 -m venv /srv/api-prime/venv
    source /srv/api-prime/venv/bin/activate

    # 5. Install Python dependencies.
    echo "Installing Python dependencies..."
    pip install -r /srv/api-prime/requirements.txt

    # 6. Configure Django Project.
    echo "Configuring Django..."
    # Find the correct settings.py, excluding the venv directory.
    SETTINGS_FILE=$(find /srv/api-prime -path /srv/api-prime/venv -prune -o -name settings.py -print | head -n 1)
    if [ -z "$SETTINGS_FILE" ]; then
        echo "ERROR: settings.py not found!"
        exit 1
    fi
    echo "Found settings.py at $SETTINGS_FILE"
    EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    echo "External IP: $EXTERNAL_IP"
    sed -i "s/^ALLOWED_HOSTS = .*/ALLOWED_HOSTS = [\"$EXTERNAL_IP\", \"localhost\", \"127.0.0.1\"]/" "$SETTINGS_FILE"
    
    # 7. Start Django App.
    echo "Starting Django app..."
    MANAGE_PY_DIR=$(dirname $(find /srv/api-prime -name manage.py | head -n 1))
    if [ -z "$MANAGE_PY_DIR" ]; then
        echo "ERROR: manage.py not found!"
        exit 1
    fi # Corrected syntax from } to fi
    echo "Found manage.py in $MANAGE_PY_DIR"
    cd "$MANAGE_PY_DIR"
    WSGI_FILE=$(find . -name wsgi.py | head -n 1)
    if [ -z "$WSGI_FILE" ]; then
        echo "ERROR: wsgi.py not found!"
        exit 1
    fi
    GUNICORN_APP_MODULE=$(echo "$WSGI_FILE" | sed 's|^./||' | sed 's|/|.|g' | sed 's|\.py$||')
    echo "Gunicorn app module: $GUNICORN_APP_MODULE:application"
    python3 manage.py migrate
    gunicorn "$GUNICORN_APP_MODULE:application" --bind 0.0.0.0:8000 --daemon

    # 8. Verify Processes.
    echo "--- Verifying Gunicorn process ---"
    ps aux | grep gunicorn
    echo "--- Verifying listening ports ---"
    netstat -tulpn | grep 8000
    echo "--- End of Startup Script ---"
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
