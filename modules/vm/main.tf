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

    # --- Configure Django Project ---

    # 1. Add '*' to ALLOWED_HOSTS for development.
    #    For production, you should lock this down to your domain name.
    sed -i "s/ALLOWED_HOSTS = []/ALLOWED_HOSTS = ['*']/" /srv/api_project/api_project/settings.py

    # 2. Add the new 'api' app and 'rest_framework' to INSTALLED_APPS
    sed -i "/'django.contrib.staticfiles',/a     'rest_framework',\n    'api'," /srv/api_project/api_project/settings.py

    # 3. Create a simple API view for testing
    cat <<'EOT' > /srv/api_project/api/views.py
from rest_framework.response import Response
from rest_framework.decorators import api_view

@api_view(['GET'])
def hello_world(request):
    return Response({'message': 'Hello, world!'})
EOT

    # 4. Create a urls.py for the 'api' app
    cat <<'EOT' > /srv/api_project/api/urls.py
from django.urls import path
from .views import hello_world

urlpatterns = [
    path('', hello_world, name='hello_world'),
]
EOT

    # 5. Include the api urls in the main project urls.py
    sed -i "/from django.urls import path/a from django.urls import include" /srv/api_project/api_project/urls.py
    sed -i "/urlpatterns = [\n/a     path('api/', include('api.urls'))," /srv/api_project/api_project/urls.py


    # --- Configure Nginx ---
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

    # --- Start Django App ---
    # Run migrations and start the development server in the background
    cd /srv/api_project
    python3 manage.py migrate
    python3 manage.py runserver 0.0.0.0:8000 &
    EOF
}

output "ip" {
  value = resource.google_compute_instance.vm.network_interface.0.network_ip
}

output "external_ip" {
  value = resource.google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}