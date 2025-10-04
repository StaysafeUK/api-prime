

resource "google_project_iam_member" "api_prime_svc_net_compute_instance_admin" {
  project = "archejrenet-dev-03102025"
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:terra-svc-net@archejrenet.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "api_prime_svc_net_compute_network_admin" {
  project = "archejrenet-dev-03102025"
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:terra-svc-net@archejrenet.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "api_prime_svc_net_compute_security_admin" {
  project = "archejrenet-dev-03102025"
  role    = "roles/compute.securityAdmin"
  member  = "serviceAccount:terra-svc-net@archejrenet.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "api_prime_svc_net_secretmanager_admin" {
  project = "archejrenet-dev-03102025"
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:terra-svc-net@archejrenet.iam.gserviceaccount.com"
}

resource "google_project_service" "secretmanager_api" {
  project            = "archejrenet-dev-03102025"
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}
