variable "vm-name" {
 description = "api-prime"
}

resource "google_compute_instance" "vm" {

	name = var.vm-name
	machine_type = "n1-standard-2"
 	zone = "europe-west1-b"
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

  metadata_startup_script = <<-EOF
    #!/bin/bash -e
    # Exit immediately if a command exits with a non-zero status.
    set -e

    # Update and install packages
    apt-get update
    apt-get install -y python3-pip git python3-venv

    # Clone the private repository
    git clone https://jrevans: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@github.com/StaysafeUK/api-prime.git /srv/api-prime

    # Create and activate a virtual environment
    python3 -m venv /srv/api-prime/venv
    source /srv/api-prime/venv/bin/activate

    # Install Python dependencies
    pip install -r /srv/api-prime/requirements.txt

    # --- Configure Django Project ---
    echo "Configuring Django..."
    # Get the external IP address from metadata server
    EXTERNAL_IP=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
    echo "External IP: $EXTERNAL_IP"

    # Add the external IP to ALLOWED_HOSTS
    sed -i "s/^ALLOWED_HOSTS = .*/ALLOWED_HOSTS = [\"$EXTERNAL_IP\"]/" /srv/api-prime/divisible_api/divisible_api/settings.py
    echo "--- settings.py after modification ---"
    cat /srv/api-prime/divisible_api/divisible_api/settings.py
    echo "------------------------------------"

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
  value = resource.google_compute_instance.vm.network_interface.0.network_ip
}

output "external_ip" {
  value = resource.google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}