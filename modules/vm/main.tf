



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

variable "instance_count" {
  description = "The number of VM instances to create."
  type        = number
  default     = 1
}

variable "region" {
  description = "The region to deploy the resources in."
  type        = string
  default     = "europe-west1"
}

variable "vm_tags" {
  description = "A list of tags to apply to the VM instances."
  type        = list(string)
  default     = []
}

variable "redis_host" {
  description = "The hostname or IP address of the Redis instance."
  type        = string
}



resource "google_compute_instance" "vm" {
  count        = var.instance_count
  name         = "${var.vm-name}-${count.index}"
  machine_type = "n1-standard-2"
  zone         = "europe-west1-b"
  tags         = concat([var.vm-name, "http-server", "django-api"], var.vm_tags)

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
    curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY=NRAK-H0ATRYM74RY2Q4L7KXE21VOWDM9 NEW_RELIC_ACCOUNT_ID=3547995 NEW_RELIC_REGION=EU /usr/local/bin/newrelic install -y

    # 3. Fetch Git Credentials.
    echo "Fetching Git User and PAT from Secret Manager..."
    GIT_USER=$(gcloud secrets versions access latest --secret="git-user" --project="archejreterra")
    GIT_PAT=$(gcloud secrets versions access latest --secret="git-pat" --project="archejreterra")

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

output "external_ip" {
  value = google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip
}

resource "google_compute_global_address" "lb_ip" {
  count  = var.instance_count > 1 ? 1 : 0
  name   = "${var.vm-name}-lb-ip"
}

resource "google_compute_instance_group" "unmanaged" {
  count = var.instance_count > 1 ? 1 : 0
  name  = "${var.vm-name}-unmanaged-instance-group"
  zone  = "europe-west1-b"

  instances = google_compute_instance.vm[*].self_link

  named_port {
    name = "http"
    port = "8000"
  }
}

resource "google_compute_health_check" "http_health_check" {
  count               = var.instance_count > 1 ? 1 : 0
  name                = "${var.vm-name}-http-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {
    port         = 8000
    request_path = "/api/health/"
  }
}

resource "google_compute_backend_service" "backend_service" {
  count                 = var.instance_count > 1 ? 1 : 0
  name                  = "${var.vm-name}-backend-service"
  protocol              = "HTTP"
  port_name             = "http"
  timeout_sec           = 12600
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.http_health_check[0].self_link]

  backend {
    group = google_compute_instance_group.unmanaged[0].self_link
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_url_map" "url_map" {
  count           = var.instance_count > 1 ? 1 : 0
  name            = "${var.vm-name}-url-map"
  default_service = google_compute_backend_service.backend_service[0].self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  count   = var.instance_count > 1 ? 1 : 0
  name    = "${var.vm-name}-http-proxy"
  url_map = google_compute_url_map.url_map[0].self_link
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  count                 = var.instance_count > 1 ? 1 : 0
  name                  = "${var.vm-name}-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy[0].self_link
  ip_address            = google_compute_global_address.lb_ip[0].address
  port_range            = "8080"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

resource "google_compute_managed_ssl_certificate" "ssl_certificate" {
  count    = var.instance_count > 1 ? 1 : 0
  name     = "${var.vm-name}-ssl-certificate"
  managed {
    domains = [var.domain_name]
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  count             = var.instance_count > 1 ? 1 : 0
  name              = "${var.vm-name}-https-proxy"
  url_map           = google_compute_url_map.url_map[0].self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.ssl_certificate[0].self_link]
}

resource "google_compute_global_forwarding_rule" "forwarding_rule_https" {
  count                 = var.instance_count > 1 ? 1 : 0
  name                  = "${var.vm-name}-forwarding-rule-https"
  target                = google_compute_target_https_proxy.https_proxy[0].self_link
  ip_address            = google_compute_global_address.lb_ip[0].address
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

variable "domain_name" {
  description = "The domain name for the SSL certificate."
  type        = string
  default     = "api-prime.example.com"
}

resource "google_compute_firewall" "allow_lb_traffic" {
  count   = var.instance_count > 1 ? 1 : 0
  name    = "${var.vm-name}-allow-lb-traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}
