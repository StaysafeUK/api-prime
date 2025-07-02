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

  tags = [var.vm-name]

  metadata_startup_script = <<-EOF
   #!/bin/bash
set -x
exec > /var/log/startup-script.log 2>&1

# Update and install packages
apt-get update
apt-get install -y python3-pip python3-venv

# Install Docker (optional for this setup, but keeping as per original)
apt-get install -y docker.io
systemctl start docker
systemctl enable docker

# Create /srv directory
mkdir -p /srv/api_project
cd /srv/api_project

# Set up virtual environment
python3 -m venv /opt/api_prime_venv
source /opt/api_prime_venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install django djangorestframework gunicorn

# Set up Django structure
mkdir -p api_project api primenumbers

# Create manage.py
cat <<'EOT' > manage.py
#!/usr/bin/env python
import os
import sys

def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'api_project.settings')
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)

if __name__ == '__main__':
    main()
EOT
chmod +x manage.py

# Create necessary files (apps.py, urls.py, settings.py, views, etc.)
# [UNCHANGED FROM YOUR ORIGINAL – THESE CAN STAY AS YOU HAD THEM]

# Instead of hardcoding primenum3.py, move it if it were copied via GCS or from metadata.
# For now, inject the uploaded version content
cat <<'EOT' > primenumbers/primenum3.py
$(cat /mnt/data/primenum3.py)
EOT

# Run migrations and collect static files
cd /srv/api_project
python manage.py migrate
python manage.py collectstatic --noinput

# Start Gunicorn
nohup gunicorn api_project.wsgi:application --bind 0.0.0.0:80 &
EOF
}

output "ip" {
  value = resource.google_compute_instance.vm.network_interface.0.network_ip
}

resource "google_compute_firewall" "http_firewall" {
  name    = "${var.vm-name}-http-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.vm-name]
}

output "external_ip" {
  value = resource.google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}
