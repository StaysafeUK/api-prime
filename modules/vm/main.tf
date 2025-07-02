variable "vm-name" {
 description = "api-prime"
}

resource "google_compute_instance" "vm" {

	name = var.vm-name
	machine_type = "f1-micro"
 	zone = "europe-west2-c"
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
    #!/bin/bash
    # Update and install packages
    apt-get update
    apt-get install -y python3-pip nginx

    # Install Docker
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker

    # Install Django and Django REST Framework
    pip3 install django djangorestframework

    # Create Django project
    django-admin startproject api_project /srv/api_project
    cd /srv/api_project
    python3 manage.py startapp api

    # Configure Nginx
    cat <<'EOT' > /etc/nginx/sites-available/default
    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://127.0.0.1:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
EOT
    systemctl restart nginx

    # Start Django app
    cd /srv/api_project && python3 manage.py runserver 0.0.0.0:8000 &
    EOF
}

output "ip" {
  value = resource.google_compute_instance.vm.network_interface.0.network_ip
}

output "external_ip" {
  value = resource.google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}