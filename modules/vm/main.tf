variable "vm-name" {}
variable "git_user" {}
variable "git_pat" { sensitive = true }
variable "git_project" {}
variable "cloud_project" {}
variable "instance_count" {}
variable "region" {}
variable "domain_name" {}
variable "redis_host" {}
variable "vm_tags" { type = list(string) }

data "google_compute_subnetwork" "dev_subnet" {
  name    = "dev-subnet"
  project = "archejrenet"
  region  = var.region
}

resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = "${var.vm-name}-${count.index}"
  machine_type = "n1-standard-2"
  zone         = "europe-west1-b"
  tags         = concat([var.vm-name, "http-server", "api-frontend", "django-api", "allow-ssh", "allow-dns-egress-dev", "allow-internet-egress-dev"], var.vm_tags)

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
    subnetwork = data.google_compute_subnetwork.dev_subnet.self_link
  }

  service_account {
    email  = "terra-svc-net@archejrenet.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    redis-host = var.redis_host
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo '--- Starting Startup Script ---'
    # Log all output to a file and the console.
    exec &> /var/log/startup.log

    set -x # Print each command before it's executed.
    set -e # Exit immediately if a command exits with a non-zero status.

    echo "--- Starting Startup Script ---"

    # 1. Install only essential packages.
    apt-get update
    apt-get install -y python3-pip git python3-venv google-cloud-sdk jq ufw

    # 2. Install New Relic Agent.
    NEW_RELIC_API_KEY=$(gcloud secrets versions access latest --secret="new-relic-api-key" --project="archejrenet")
    curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY=$NEW_RELIC_API_KEY NEW_RELIC_ACCOUNT_ID=3547995 NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y

    # 3. Fetch Git Credentials.
    echo "Fetching Git User and PAT from Secret Manager..."
    GIT_USER=$(gcloud secrets versions access latest --secret="git-user" --project="archejrenet")
    GIT_PAT=$(gcloud secrets versions access latest --secret="git-pat" --project="archejrenet")

    # 4. Clone Repository.
    echo "Cloning private repository..."
    git clone --branch primeworker "https://$GIT_USER:$GIT_PAT@github.com/StaysafeUK/${var.git_project}.git" /srv/api-prime
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to clone repository. Please check your Git credentials (Personal Access Token) and repository permissions."
        exit 1
    fi

    # 5. Setup Virtual Environment.
    echo "Setting up Python virtual environment..."
    python3 -m venv /srv/api-prime/venv
    
    # 6. Install Python dependencies.
    echo "Installing Python dependencies..."
    /srv/api-prime/venv/bin/pip install -r /srv/api-prime/requirements.txt

    # 7. Configure Django Project.
    echo "Configuring Django..."
    SETTINGS_FILE=/srv/api-prime/divisible_api/divisible_api/settings.py
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo "ERROR: settings.py not found at $SETTINGS_FILE!"
        exit 1
    fi
    echo "Found settings.py at $SETTINGS_FILE"
    EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    echo "External IP: $EXTERNAL_IP"

    # Update the settings.py file
    echo "Attempting to modify ALLOWED_HOSTS in $SETTINGS_FILE..."
    sed -i "s/^ALLOWED_HOSTS = .*/ALLOWED_HOSTS = ['*']/" "$SETTINGS_FILE"
    if [ $? -eq 0 ]; then
        echo "Successfully modified ALLOWED_HOSTS."
        echo "--- Contents of settings.py after modification ---"
        cat "$SETTINGS_FILE"
        echo "--- End of settings.py ---"
    else
        echo "ERROR: Failed to modify ALLOWED_HOSTS."
        exit 1
    fi
    
    # 8. Start Django App.
    echo "Starting Django app..."
    cd /srv/api-prime/divisible_api
    /srv/api-prime/venv/bin/python3 manage.py migrate

    echo "--- Configuring UFW Firewall ---"
    ufw --force enable
    ufw allow 22/tcp
    ufw allow 8000/tcp

    export REDIS_HOST=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/redis-host)
    /srv/api-prime/venv/bin/gunicorn divisible_api.wsgi:application --bind 0.0.0.0:8000 --access-logfile /var/log/gunicorn_access.log --error-logfile /var/log/gunicorn_error.log &

    # 9. Verify Processes.
    echo "--- Verifying Gunicorn process ---"
    sleep 5 # give gunicorn a moment to start
    ps aux | grep gunicorn
    echo "--- Verifying listening ports ---"
    netstat -tulpn | grep 8000
    echo "--- End of Startup Script ---"
    EOF
}

output "ip" {
  value = google_compute_instance.vm[*].network_interface[0].network_ip
}